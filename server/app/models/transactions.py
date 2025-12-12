from sqlalchemy import Column, Integer, String, Numeric, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    
    amount = Column(Numeric(14, 2), nullable=True)
    merchant = Column(String, nullable=True)
    category = Column(String, nullable=True)
    upiId = Column(String, nullable=True)
    transactionId = Column(String, nullable=True, index=True)
    timestamp = Column(DateTime(timezone=True), nullable=True)
    type = Column(String, nullable=True)  # "debit" / "credit"
    balance = Column(Numeric(14, 2), nullable=True)
    bankName = Column(String, nullable=True)
    accountNumber = Column(String, nullable=True)
    rawMessage = Column(String, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", back_populates="transactions")
