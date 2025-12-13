from fastapi import APIRouter, Request, HTTPException, BackgroundTasks, Form
from fastapi.responses import Response, PlainTextResponse
import httpx
import logging
from twilio.rest import Client
from twilio.twiml.messaging_response import MessagingResponse
from sqlalchemy.orm import Session
from datetime import datetime

from app.core.config import settings
from app.database import get_db, SessionLocal
from app.models.user import User
from app.models.transactions import Transaction
from app.utils.ocr import OCRAgent
from app.utils.pdf_to_text import extract_text_from_pdf

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

router = APIRouter(prefix="/twilio", tags=["Twilio Webhooks"])

# Initialize Twilio client only if credentials are provided
def get_twilio_client():
    """Get Twilio client if credentials are configured, otherwise return None"""
    if settings.twilio_account_sid and settings.twilio_auth_token:
        return Client(settings.twilio_account_sid, settings.twilio_auth_token)
    return None

twilio_client = get_twilio_client()


def send_whatsapp_message(to: str, body: str):
    """Send a WhatsApp message via Twilio"""
    if not twilio_client:
        logger.warning("⚠️ Twilio not configured - cannot send WhatsApp message")
        return None
    
    try:
        logger.info(f"📱 Sending WhatsApp message to {to}")
        message = twilio_client.messages.create(
            body=body,
            from_=settings.twilio_whatsapp_from,
            to=to
        )
        logger.info(f"✅ Message sent: {message.sid}")
        return message
    except Exception as e:
        logger.error(f"❌ Error sending message: {e}")
        return None


@router.post("/whatsapp/webhook")
async def whatsapp_webhook(
    background_tasks: BackgroundTasks,
    From: str = Form(...),
    Body: str = Form(None),
    MediaUrl0: str = Form(None),
    MediaContentType0: str = Form(None),
    NumMedia: str = Form("0")
):
    """
    Webhook endpoint for receiving WhatsApp messages from Twilio.
    Processes images/PDFs through OCR and adds transactions to user account.
    """
    try:
        logger.info(f"📱 Received WhatsApp message from {From}")
        logger.info(f"📱 Body: {Body}, NumMedia: {NumMedia}")
        
        response = MessagingResponse()
        
        # Handle text commands
        if Body:
            message_text = Body.strip().lower()
            
            if message_text in ["help", "start", "reset"]:
                welcome_msg = (
                    "💰 *Kronyx Expense Tracker*\n\n"
                    "Welcome! I can automatically track your expenses.\n\n"
                    "📋 *How it works:*\n"
                    "1. Send me a transaction receipt (image or PDF)\n"
                    "2. I'll extract the transaction details using OCR\n"
                    "3. The expense is automatically added to your account\n\n"
                    "📸 *Send your receipt now!*\n\n"
                    "💡 Commands:\n"
                    "• `help` - Show this message\n"
                    "• `balance` - Check your balance\n"
                    "• `recent` - Show recent transactions"
                )
                response.message(welcome_msg)
                return PlainTextResponse(content=str(response), media_type="application/xml")
            
            elif message_text == "balance":
                # Get user balance
                db = SessionLocal()
                try:
                    # Extract phone number without whatsapp: prefix
                    phone = From.replace('whatsapp:', '')
                    user = db.query(User).filter(User.phone_number == phone).first()
                    
                    # Try without country code if not found
                    if not user and phone.startswith('+'):
                        phone_without_code = phone[1:]
                        for length in [2, 3, 1]:
                            phone_variant = phone_without_code[length:]
                            user = db.query(User).filter(User.phone_number == phone_variant).first()
                            if user:
                                break
                    
                    if user:
                        balance_msg = (
                            f"💰 *Your Account Balance*\n\n"
                            f"Balance: ₹{user.savings:,.2f}\n"
                            f"Name: {user.name}\n\n"
                            "📸 Send a receipt to add a new expense!"
                        )
                    else:
                        balance_msg = (
                            "❌ *Account Not Found*\n\n"
                            f"No account linked to {phone}\n\n"
                            "Please contact support to link your WhatsApp number."
                        )
                    response.message(balance_msg)
                finally:
                    db.close()
                
                return PlainTextResponse(content=str(response), media_type="application/xml")
            
            elif message_text == "recent":
                # Get recent transactions
                db = SessionLocal()
                try:
                    phone = From.replace('whatsapp:', '')
                    user = db.query(User).filter(User.phone_number == phone).first()
                    
                    # Try without country code if not found
                    if not user and phone.startswith('+'):
                        phone_without_code = phone[1:]
                        for length in [2, 3, 1]:
                            phone_variant = phone_without_code[length:]
                            user = db.query(User).filter(User.phone_number == phone_variant).first()
                            if user:
                                break
                    
                    if user:
                        transactions = db.query(Transaction).filter(
                            Transaction.user_id == user.id
                        ).order_by(Transaction.timestamp.desc()).limit(5).all()
                        
                        if transactions:
                            msg = "📊 *Recent Transactions*\n\n"
                            for txn in transactions:
                                date = txn.timestamp.strftime("%d %b") if txn.timestamp else "N/A"
                                msg += f"• {date} - {txn.merchant or 'Unknown'}\n  ₹{txn.amount:,.2f} ({txn.type})\n\n"
                        else:
                            msg = "📭 No transactions found.\n\n📸 Send a receipt to add your first expense!"
                    else:
                        msg = "❌ Account not found. Please contact support."
                    
                    response.message(msg)
                finally:
                    db.close()
                
                return PlainTextResponse(content=str(response), media_type="application/xml")
        
        # Handle media (images/PDFs)
        if int(NumMedia) > 0 and MediaUrl0:
            logger.info(f"📄 Processing media: {MediaContentType0}")
            
            response.message(
                "📄 *Receipt Received!*\n\n"
                "🔍 Processing your transaction...\n"
                "This will take 10-20 seconds."
            )
            
            # Process media in background
            background_tasks.add_task(
                process_media_ocr,
                from_number=From,
                media_url=MediaUrl0,
                content_type=MediaContentType0
            )
            
            return PlainTextResponse(content=str(response), media_type="application/xml")
        
        # No media or recognized command
        if not int(NumMedia) > 0:
            response.message(
                "📸 *Send a receipt image or PDF* to track your expense!\n\n"
                "💡 Type 'help' for instructions."
            )
        
        return PlainTextResponse(content=str(response), media_type="application/xml")
        
    except Exception as e:
        logger.error(f"❌ Webhook error: {e}")
        response = MessagingResponse()
        response.message(f"❌ Error: {str(e)}")
        return PlainTextResponse(content=str(response), media_type="application/xml")


async def process_media_ocr(from_number: str, media_url: str, content_type: str):
    """
    Background task to download media, perform OCR, and add transaction to user account.
    """
    db = SessionLocal()
    try:
        logger.info(f"🔍 Processing media from {from_number}")
        
        # Extract phone number and remove whatsapp: prefix
        phone = from_number.replace('whatsapp:', '')
        
        # Try to find user with exact match first
        user = db.query(User).filter(User.phone_number == phone).first()
        
        # If not found, try without country code (remove +91, +1, etc.)
        if not user and phone.startswith('+'):
            # Remove + and country code (assuming 1-3 digit country codes)
            phone_without_code = phone[1:]  # Remove +
            # Try variations: without country code entirely
            for length in [2, 3, 1]:  # Try 2-digit, 3-digit, 1-digit country codes
                phone_variant = phone_without_code[length:]
                user = db.query(User).filter(User.phone_number == phone_variant).first()
                if user:
                    logger.info(f"✅ Found user with phone variant: {phone_variant}")
                    break
                # Also try with just the country code removed but keeping +
                user = db.query(User).filter(User.phone_number == '+' + phone_variant).first()
                if user:
                    logger.info(f"✅ Found user with phone variant: +{phone_variant}")
                    break
        
        if not user:
            logger.error(f"❌ User not found for phone: {phone}")
            send_whatsapp_message(
                from_number,
                f"❌ *Account Not Found*\n\n"
                f"No account linked to {phone}\n\n"
                "Please contact support to link your WhatsApp number to your Kronyx account."
            )
            return
        
        # Download media from Twilio (follow redirects to CDN)
        if not settings.twilio_account_sid or not settings.twilio_auth_token:
            logger.error("❌ Twilio credentials not configured")
            send_whatsapp_message(
                from_number,
                "❌ *Service Unavailable*\n\n"
                "Twilio service is not configured. Please contact support."
            )
            return
        
        auth = (settings.twilio_account_sid, settings.twilio_auth_token)
        
        async with httpx.AsyncClient(follow_redirects=True) as client:
            media_response = await client.get(media_url, auth=auth)
            media_response.raise_for_status()
            file_data = media_response.content
        
        logger.info(f"✅ Downloaded media: {len(file_data)} bytes")
        
        # Process based on content type
        ocr_agent = OCRAgent()
        
        if content_type == 'application/pdf':
            # Extract text from PDF first
            extracted_text = extract_text_from_pdf(file_data)
            if not extracted_text:
                raise Exception("No text found in PDF")
            
            # Extract transaction from text
            transaction_data = await ocr_agent.extract_transaction_from_text(extracted_text)
        else:
            # Process image directly
            transaction_data = await ocr_agent.extract_transaction(file_data)
        
        logger.info(f"✅ OCR extracted: {transaction_data}")
        
        # Update user_id to the actual user
        transaction_data.user_id = user.id
        
        # Create transaction in database
        new_transaction = Transaction(
            user_id=transaction_data.user_id,
            amount=transaction_data.amount,
            merchant=transaction_data.merchant,
            category=transaction_data.category,
            upiId=transaction_data.upiId,
            transactionId=transaction_data.transactionId,
            timestamp=transaction_data.timestamp or datetime.now(),
            type=transaction_data.type,
            balance=transaction_data.balance,
            bankName=transaction_data.bankName,
            accountNumber=transaction_data.accountNumber,
            rawMessage=transaction_data.rawMessage
        )
        
        db.add(new_transaction)
        db.commit()
        db.refresh(new_transaction)
        
        logger.info(f"✅ Transaction saved: ID {new_transaction.id}")
        
        # Send confirmation message
        confirmation_msg = (
            f"✅ *Transaction Added Successfully!*\n\n"
            f"💰 Amount: ₹{transaction_data.amount:,.2f}\n"
            f"🏪 Merchant: {transaction_data.merchant or 'N/A'}\n"
            f"📅 Date: {transaction_data.timestamp.strftime('%d %b %Y, %I:%M %p') if transaction_data.timestamp else 'N/A'}\n"
            f"📊 Type: {transaction_data.type.upper()}\n"
        )
        
        if transaction_data.category:
            confirmation_msg += f"🏷️ Category: {transaction_data.category}\n"
        
        if transaction_data.transactionId:
            confirmation_msg += f"🔖 Txn ID: {transaction_data.transactionId}\n"
        
        confirmation_msg += f"\n💡 Your balance: ₹{user.savings:,.2f}\n"
        confirmation_msg += "\n📸 Send another receipt to track more expenses!"
        
        send_whatsapp_message(from_number, confirmation_msg)
        
    except Exception as e:
        logger.error(f"❌ Error processing OCR: {e}")
        send_whatsapp_message(
            from_number,
            f"❌ *Processing Failed*\n\n"
            f"Error: {str(e)}\n\n"
            "💡 Try:\n"
            "• Taking a clearer photo\n"
            "• Ensuring good lighting\n"
            "• Sending a PDF if available"
        )
    finally:
        db.close()
