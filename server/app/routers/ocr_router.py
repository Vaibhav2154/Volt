from typing import List, Annotated, Optional
from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile
from sqlalchemy.orm import Session

from app.database import get_db
from app.oauth2 import get_current_user
from app.models.user import User
from app.models.transactions import Transaction
from app.schemas.transaction_schemas import TransactionCreate, TransactionResponse
from app.utils.ocr import OCRAgent

router = APIRouter(
    prefix="/ocr",
    tags=["OCR"]
)

@router.post("/images-to-text", response_model=TransactionCreate)
async def extract_text_from_images(
    file: UploadFile = File(...)
):
    """
    Extract transaction details from an image using OCR.
    
    - **file**: Image file (JPEG/PNG) of a transaction
    - Returns transaction data as JSON
    """
    try:
        # Validate file type
        if file.content_type and not (file.content_type.startswith('image/') or file.content_type == 'application/octet-stream'):
            raise HTTPException(status_code=400, detail=f"File is not an image")
        
        # Read file content
        content = await file.read()
        if not content:
            raise HTTPException(status_code=400, detail=f"File is empty")

        # Extract transaction using OCR Agent
        ocr_agent = OCRAgent()
        transaction_data = await ocr_agent.extract_transaction(content)
        
        return transaction_data

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error processing image: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Transaction extraction failed: {str(e)}")
