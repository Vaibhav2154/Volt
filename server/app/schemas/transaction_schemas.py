from pydantic import BaseModel, Field, field_validator
from typing import Optional, Literal
from datetime import datetime
from decimal import Decimal

class TransactionBase(BaseModel):
    """Base transaction schema with validation"""
    amount: Decimal = Field(..., gt=0, description="Transaction amount (must be positive)")
    merchant: Optional[str] = Field(None, max_length=200)
    category: Optional[str] = Field(None, max_length=50)
    upiId: Optional[str] = Field(None, max_length=100)
    transactionId: Optional[str] = Field(None, max_length=100)
    timestamp: Optional[datetime] = None
    type: Literal["debit", "credit"] = Field(..., description="Transaction type")
    balance: Optional[Decimal] = None
    bankName: Optional[str] = Field(None, max_length=100)
    accountNumber: Optional[str] = Field(None, max_length=50)
    rawMessage: Optional[str] = Field(None, max_length=1000)

    @field_validator('amount', 'balance')
    @classmethod
    def validate_decimal_places(cls, v):
        if v is not None and v.as_tuple().exponent < -2:
            raise ValueError('Maximum 2 decimal places allowed')
        return v


class TransactionCreate(TransactionBase):
    """Schema for creating a transaction"""
    user_id: int = Field(..., gt=0)


class TransactionResponse(TransactionBase):
    """Schema for transaction response"""
    id: int
    user_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True  



