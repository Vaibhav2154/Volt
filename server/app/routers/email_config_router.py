"""
Email Configuration Router
Endpoints for managing user email parsing settings
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Annotated

from app.database import get_db
from app.oauth2 import get_current_user
from app.models.user import User
from app.schemas.email_config_schema import (
    EmailAppPasswordRequest,
    EmailAppPasswordResponse,
    EmailParsingStatusResponse,
    DisableEmailParsingRequest
)
from app.services.email_config_service import EmailConfigService
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/email-config", tags=["Email Configuration"])

email_config_service = EmailConfigService()


@router.post("/setup-app-password", response_model=EmailAppPasswordResponse)
async def setup_app_password(
    request: EmailAppPasswordRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """
    Setup Gmail app password for email parsing
    
    User must:
    1. Provide their Gmail app password (16 characters)
    2. Give consent to enable email parsing
    
    The password is encrypted before storage.
    """
    # Validate consent
    if not request.consent:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User consent is required to enable email parsing"
        )
    
    # Validate app password format
    if not email_config_service.validate_app_password_format(request.app_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid app password format. Gmail app passwords are 16 characters long."
        )
    
    try:
        # Encrypt the app password
        encrypted_password = email_config_service.encrypt_app_password(request.app_password)
        
        # Update user record
        current_user.email_app_password = encrypted_password
        current_user.email_parsing_enabled = True
        
        db.commit()
        db.refresh(current_user)
        
        logger.info(f"Email parsing enabled for user: {current_user.email}")
        
        return EmailAppPasswordResponse(
            status="success",
            email_parsing_enabled=True,
            message=f"Email parsing enabled for {current_user.email}. Transaction emails will be automatically processed."
        )
        
    except ValueError as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
    except Exception as e:
        db.rollback()
        logger.error(f"Failed to setup app password: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to setup email parsing"
        )


@router.get("/status", response_model=EmailParsingStatusResponse)
async def get_email_parsing_status(
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Get current email parsing status for the authenticated user"""
    return EmailParsingStatusResponse(
        email_parsing_enabled=current_user.email_parsing_enabled or False,
        email_address=current_user.email if current_user.email_parsing_enabled else None,
        has_app_password=current_user.email_app_password is not None,
        message="Email parsing is active" if current_user.email_parsing_enabled 
                else "Email parsing is disabled. Setup app password to enable."
    )


@router.post("/disable", response_model=EmailAppPasswordResponse)
async def disable_email_parsing(
    request: DisableEmailParsingRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """Disable email parsing and remove stored app password"""
    if not request.confirm:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Confirmation required to disable email parsing"
        )
    
    try:
        # Clear app password and disable parsing
        current_user.email_app_password = None
        current_user.email_parsing_enabled = False
        
        db.commit()
        db.refresh(current_user)
        
        logger.info(f"Email parsing disabled for user: {current_user.email}")
        
        return EmailAppPasswordResponse(
            status="success",
            email_parsing_enabled=False,
            message="Email parsing disabled. Your app password has been removed."
        )
        
    except Exception as e:
        db.rollback()
        logger.error(f"Failed to disable email parsing: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to disable email parsing"
        )


@router.post("/update-app-password", response_model=EmailAppPasswordResponse)
async def update_app_password(
    request: EmailAppPasswordRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """Update Gmail app password (same as setup)"""
    return await setup_app_password(request, current_user, db)
