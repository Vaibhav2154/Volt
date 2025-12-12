from datetime import datetime
from typing import Annotated, List, Optional
import os

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_

from app.database import get_db
from app.models.transactions import Transaction
from app.models.user import User
from app.oauth2 import get_current_user
from app.schemas.transaction_schemas import TransactionCreate, TransactionResponse
from app.services.behavior_engine import BehaviorEngine
from app.services.categorization import CategorizationService

router = APIRouter(prefix="/transactions", tags=["Transactions"])

# Initialize services for behavior tracking
categorization_service = CategorizationService(
    gemini_api_key=os.getenv("GEMINI_API_KEY")
)
behavior_engine = BehaviorEngine(categorization_service)


@router.post("/", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
async def create_transaction(
    transaction: TransactionCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """Create a new transaction with automatic categorization."""
    # Verify the transaction belongs to the current user
    if transaction.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to create transaction for another user"
        )
    
    # Create transaction
    new_transaction = Transaction(**transaction.model_dump())
    db.add(new_transaction)
    
    # Update user savings based on transaction type
    if transaction.type == "credit":
        current_user.savings += transaction.amount
    elif transaction.type == "debit":
        current_user.savings -= transaction.amount
    
    db.commit()
    db.refresh(new_transaction)
    
    # Update behavior model with AI categorization
    await behavior_engine.update_model(db, new_transaction.user_id, new_transaction)
    
    return new_transaction


@router.post("/bulk", response_model=List[TransactionResponse], status_code=status.HTTP_201_CREATED)
async def create_multiple_transactions(
    transactions: List[TransactionCreate],
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """Create multiple transactions at once with automatic categorization."""
    # Verify all transactions belong to the current user
    for transaction in transactions:
        if transaction.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to create transactions for another user"
            )
    
    # Create all transactions
    new_transactions = [Transaction(**t.model_dump()) for t in transactions]
    db.add_all(new_transactions)
    
    # Update user savings for each transaction
    for transaction in transactions:
        if transaction.type == "credit":
            current_user.savings += transaction.amount
        elif transaction.type == "debit":
            current_user.savings -= transaction.amount
    
    db.commit()
    
    # Refresh all to get IDs and created_at
    for t in new_transactions:
        db.refresh(t)
    
    # Update behavior model for each transaction
    for t in new_transactions:
        await behavior_engine.update_model(db, t.user_id, t)
    
    return new_transactions


@router.get("/", response_model=List[TransactionResponse])
async def get_transactions(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000)
):
    """Get all transactions for the current user."""
    transactions = db.query(Transaction).filter(
        Transaction.user_id == current_user.id
    ).order_by(Transaction.timestamp.desc()).offset(skip).limit(limit).all()
    return transactions


@router.get("/date-range", response_model=List[TransactionResponse])
async def get_transactions_by_date_range(
    start_date: datetime = Query(..., description="Start date/time (ISO format)"),
    end_date: datetime = Query(..., description="End date/time (ISO format)"),
    current_user: Annotated[User, Depends(get_current_user)] = None,
    db: Session = Depends(get_db)
):
    """Get all transactions between two dates for the current user."""
    if start_date > end_date:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="start_date must be before end_date"
        )
    
    transactions = db.query(Transaction).filter(
        and_(
            Transaction.user_id == current_user.id,
            Transaction.timestamp >= start_date,
            Transaction.timestamp <= end_date
        )
    ).order_by(Transaction.timestamp.desc()).all()
    
    return transactions


@router.get("/{transaction_id}", response_model=TransactionResponse)
async def get_transaction(
    transaction_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """Get a specific transaction by ID."""
    transaction = db.query(Transaction).filter(
        Transaction.id == transaction_id,
        Transaction.user_id == current_user.id
    ).first()
    
    if not transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction not found"
        )
    
    return transaction


@router.put("/{transaction_id}", response_model=TransactionResponse)
async def update_transaction(
    transaction_id: int,
    transaction_update: TransactionCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """Update a transaction."""
    # Verify the update belongs to the current user
    if transaction_update.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update transaction for another user"
        )
    
    transaction = db.query(Transaction).filter(
        Transaction.id == transaction_id,
        Transaction.user_id == current_user.id
    ).first()
    
    if not transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction not found"
        )
    
    # Reverse the old transaction's effect on savings
    if transaction.type == "credit":
        current_user.savings -= transaction.amount
    elif transaction.type == "debit":
        current_user.savings += transaction.amount
    
    # Update transaction fields
    for key, value in transaction_update.model_dump().items():
        setattr(transaction, key, value)
    
    # Apply the new transaction's effect on savings
    if transaction_update.type == "credit":
        current_user.savings += transaction_update.amount
    elif transaction_update.type == "debit":
        current_user.savings -= transaction_update.amount
    
    db.commit()
    db.refresh(transaction)
    return transaction


@router.delete("/{transaction_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_transaction(
    transaction_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """Delete a transaction."""
    transaction = db.query(Transaction).filter(
        Transaction.id == transaction_id,
        Transaction.user_id == current_user.id
    ).first()
    
    if not transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction not found"
        )
    
    db.delete(transaction)
    db.commit()
    return None
