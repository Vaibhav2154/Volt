"""
IMAP Email Poller Service
Polls an IMAP mailbox for bank transaction emails
"""
import imaplib
from email import message_from_bytes
from email.header import decode_header
from email.message import Message
import time
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class IMAPPoller:
    """Poll IMAP mailbox for new emails"""
    
    def __init__(
        self,
        imap_server: str,
        imap_port: int,
        email_address: str,
        email_password: str,
        poll_interval: int = 60,
        mailbox: str = "INBOX"
    ):
        self.imap_server = imap_server
        self.imap_port = imap_port
        self.email_address = email_address
        self.email_password = email_password
        self.poll_interval = poll_interval
        self.mailbox = mailbox
        self.mail: Optional[imaplib.IMAP4_SSL] = None
        
    def connect(self) -> bool:
        """Connect to IMAP server"""
        try:
            self.mail = imaplib.IMAP4_SSL(self.imap_server, self.imap_port)
            self.mail.login(self.email_address, self.email_password)
            self.mail.select(self.mailbox)
            logger.info(f"Connected to IMAP server: {self.imap_server}")
            return True
        except Exception as e:
            logger.error(f"Failed to connect to IMAP: {e}")
            self.mail = None
            return False
    
    def disconnect(self):
        """Disconnect from IMAP server"""
        if self.mail:
            try:
                self.mail.close()
                self.mail.logout()
                logger.info("Disconnected from IMAP server")
            except Exception as e:
                logger.error(f"Error disconnecting: {e}")
            finally:
                self.mail = None
    
    def decode_header_value(self, value: str) -> str:
        """Decode email header value"""
        if not value:
            return ""
        
        decoded_parts = decode_header(value)
        decoded_string = ""
        
        for part, encoding in decoded_parts:
            if isinstance(part, bytes):
                try:
                    decoded_string += part.decode(encoding or 'utf-8', errors='ignore')
                except Exception:
                    decoded_string += part.decode('utf-8', errors='ignore')
            else:
                decoded_string += str(part)
        
        return decoded_string
    
    def get_email_body(self, msg: Message) -> str:
        """Extract email body from message"""
        body = ""
        
        if msg.is_multipart():
            for part in msg.walk():
                content_type = part.get_content_type()
                content_disposition = str(part.get("Content-Disposition", ""))
                
                if content_type == "text/plain" and "attachment" not in content_disposition:
                    try:
                        payload = part.get_payload(decode=True)
                        if payload:
                            charset = part.get_content_charset() or 'utf-8'
                            body += payload.decode(charset, errors='ignore')
                    except Exception as e:
                        logger.error(f"Error decoding email part: {e}")
        else:
            try:
                payload = msg.get_payload(decode=True)
                if payload:
                    charset = msg.get_content_charset() or 'utf-8'
                    body = payload.decode(charset, errors='ignore')
            except Exception as e:
                logger.error(f"Error decoding email body: {e}")
        
        return body.strip()
    
    def is_bank_email(self, sender: str, subject: str) -> bool:
        """Check if email is from a bank"""
        bank_keywords = [
            'hdfc', 'icici', 'sbi', 'axis', 'kotak', 'pnb',
            'bank', 'upi', 'transaction', 'account'
        ]
        
        sender_lower = sender.lower()
        subject_lower = subject.lower()
        
        # Check if sender or subject contains bank-related keywords
        for keyword in bank_keywords:
            if keyword in sender_lower or keyword in subject_lower:
                return True
        
        return False
    
    def fetch_new_emails(self, since_minutes: int = 60) -> List[Dict[str, Any]]:
        """
        Fetch new emails from the last N minutes
        Returns list of email dictionaries with sender, subject, body, date
        """
        if not self.mail:
            if not self.connect():
                return []
        
        emails = []
        
        try:
            # Search for emails from the last N minutes
            since_date = (datetime.now() - timedelta(minutes=since_minutes)).strftime("%d-%b-%Y")
            
            # Search for unseen emails or emails since date
            status, messages = self.mail.search(None, f'(SINCE {since_date})')
            
            if status != "OK":
                logger.error("Failed to search emails")
                return []
            
            email_ids = messages[0].split()
            logger.info(f"Found {len(email_ids)} emails since {since_date}")
            
            # Fetch each email
            for email_id in email_ids:
                try:
                    status, msg_data = self.mail.fetch(email_id, "(RFC822)")
                    
                    if status != "OK":
                        continue
                    
                    for response_part in msg_data:
                        if isinstance(response_part, tuple):
                            msg = message_from_bytes(response_part[1])
                            
                            # Extract email details
                            sender = self.decode_header_value(msg.get("From", ""))
                            subject = self.decode_header_value(msg.get("Subject", ""))
                            date_str = msg.get("Date", "")
                            body = self.get_email_body(msg)
                            
                            # Only process bank-related emails
                            if self.is_bank_email(sender, subject):
                                email_data = {
                                    "sender": sender,
                                    "subject": subject,
                                    "body": body,
                                    "date": date_str,
                                    "email_id": email_id.decode()
                                }
                                emails.append(email_data)
                                logger.info(f"Fetched email from {sender}: {subject}")
                
                except Exception as e:
                    logger.error(f"Error fetching email {email_id}: {e}")
                    continue
        
        except Exception as e:
            logger.error(f"Error during email fetch: {e}")
            self.disconnect()
        
        return emails
    
    def mark_as_read(self, email_id: str):
        """Mark email as read"""
        if not self.mail:
            return
        
        try:
            self.mail.store(email_id, '+FLAGS', '\\Seen')
        except Exception as e:
            logger.error(f"Error marking email as read: {e}")
    
    def poll_continuously(self, callback, mark_read: bool = True):
        """
        Continuously poll for new emails and call callback function
        callback should accept a list of email dictionaries
        """
        logger.info(f"Starting continuous polling every {self.poll_interval} seconds")
        
        while True:
            try:
                emails = self.fetch_new_emails(since_minutes=self.poll_interval // 60 + 1)
                
                if emails:
                    logger.info(f"Processing {len(emails)} new emails")
                    callback(emails)
                    
                    # Mark emails as read if requested
                    if mark_read:
                        for email_data in emails:
                            self.mark_as_read(email_data['email_id'])
                
                time.sleep(self.poll_interval)
                
            except KeyboardInterrupt:
                logger.info("Polling interrupted by user")
                break
            except Exception as e:
                logger.error(f"Error in polling loop: {e}")
                self.disconnect()
                time.sleep(self.poll_interval)
                self.connect()
        
        self.disconnect()
