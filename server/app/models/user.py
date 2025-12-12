from sqlalchemy import Column, Integer, String, Boolean, Numeric
from app.database import Base
from sqlalchemy.orm import relationship

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    phone_number = Column(String, nullable=False)
    hashed_password = Column(String, nullable=False)
    email_app_password = Column(String, nullable=True)  # Encrypted Gmail app password
    email_parsing_enabled = Column(Boolean, default=False, nullable=False)
    savings = Column(Numeric(14, 2), default=0, nullable=False)  # User's current savings/balance

    # Relationships
    transactions = relationship("Transaction", back_populates="user")
    behaviour_model = relationship("BehaviourModel", back_populates="user", uselist=False)
    goals = relationship("Goal", back_populates="user")