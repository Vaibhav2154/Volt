from pydantic import BaseModel, Field
from typing import Optional


class EmailAppPasswordRequest(BaseModel):
    """Request to set Gmail app password"""
    app_password: str = Field(..., description="Gmail app password (16 characters)")
    consent: bool = Field(..., description="User consent to enable email parsing")


class EmailAppPasswordResponse(BaseModel):
    """Response after setting app password"""
    status: str
    email_parsing_enabled: bool
    message: str


class EmailParsingStatusResponse(BaseModel):
    """Email parsing status for user"""
    email_parsing_enabled: bool
    email_address: Optional[str] = None
    has_app_password: bool
    message: str


class DisableEmailParsingRequest(BaseModel):
    """Request to disable email parsing"""
    confirm: bool = Field(..., description="Confirmation to disable email parsing")
