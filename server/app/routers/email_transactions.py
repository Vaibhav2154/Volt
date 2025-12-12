"""
Email Transaction Router
Endpoints for managing email transaction processing
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Dict, Any
from pydantic import BaseModel
from datetime import datetime

from app.database import get_db
from app.models.transactions import Transaction
from app.services.job_queue import JobQueue
from app.core.config import settings

router = APIRouter(prefix="/email-transactions", tags=["Email Transactions"])


# Pydantic models
class JobStats(BaseModel):
    queued: int
    processing: int
    failed: int


class JobStatus(BaseModel):
    job_id: str
    job_type: str
    status: str
    created_at: str
    started_at: str | None = None
    completed_at: str | None = None
    failed_at: str | None = None
    attempts: int
    last_error: str | None = None


class ManualEmailJob(BaseModel):
    sender: str
    subject: str
    body: str
    user_id: int = 1


class TransactionResponse(BaseModel):
    id: int
    user_id: int
    amount: float | None
    merchant: str | None
    type: str | None
    transactionId: str | None
    timestamp: datetime | None
    bankName: str | None
    
    class Config:
        from_attributes = True


def get_job_queue() -> JobQueue:
    """Dependency to get job queue instance"""
    return JobQueue(redis_url=settings.redis_url, queue_name="transaction_emails")


@router.get("/queue/stats", response_model=JobStats)
async def get_queue_stats(queue: JobQueue = Depends(get_job_queue)):
    """Get current job queue statistics"""
    stats = queue.get_queue_stats()
    return JobStats(**stats)


@router.get("/queue/job/{job_id}", response_model=JobStatus)
async def get_job_status(job_id: str, queue: JobQueue = Depends(get_job_queue)):
    """Get status of a specific job"""
    job = queue.get_job_status(job_id)
    
    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Job {job_id} not found"
        )
    
    return JobStatus(**job)


@router.post("/queue/manual", status_code=status.HTTP_201_CREATED)
async def enqueue_manual_email(
    email_job: ManualEmailJob,
    queue: JobQueue = Depends(get_job_queue)
):
    """
    Manually enqueue an email for processing
    Useful for testing or processing emails outside the poller
    """
    from app.services.email_parser import parse_bank_email
    
    # Parse the email
    transaction_data = parse_bank_email(
        subject=email_job.subject,
        body=email_job.body,
        sender=email_job.sender
    )
    
    if not transaction_data.get("amount") and not transaction_data.get("transactionId"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not extract transaction data from email"
        )
    
    # Enqueue job
    job_data = {
        "transaction": transaction_data,
        "email_metadata": {
            "sender": email_job.sender,
            "subject": email_job.subject,
            "date": datetime.utcnow().isoformat()
        }
    }
    
    job_id = queue.enqueue(
        job_type="process_transaction",
        data=job_data,
        priority=1
    )
    
    return {
        "message": "Email enqueued for processing",
        "job_id": job_id,
        "transaction_preview": {
            "amount": transaction_data.get("amount"),
            "merchant": transaction_data.get("merchant"),
            "type": transaction_data.get("type"),
            "bank": transaction_data.get("bankName")
        }
    }


@router.get("/transactions/recent", response_model=List[TransactionResponse])
async def get_recent_transactions(
    limit: int = 20,
    db: Session = Depends(get_db)
):
    """Get recent transactions inserted from emails"""
    transactions = db.query(Transaction)\
        .order_by(Transaction.created_at.desc())\
        .limit(limit)\
        .all()
    
    return transactions


@router.get("/transactions/by-bank/{bank_name}", response_model=List[TransactionResponse])
async def get_transactions_by_bank(
    bank_name: str,
    limit: int = 20,
    db: Session = Depends(get_db)
):
    """Get transactions from a specific bank"""
    transactions = db.query(Transaction)\
        .filter(Transaction.bankName.ilike(f"%{bank_name}%"))\
        .order_by(Transaction.created_at.desc())\
        .limit(limit)\
        .all()
    
    return transactions


@router.delete("/queue/clear")
async def clear_queue(queue: JobQueue = Depends(get_job_queue)):
    """
    Clear all pending jobs from queue
    WARNING: This will remove all queued jobs
    """
    queue.clear_queue()
    return {"message": "Queue cleared successfully"}


@router.get("/health")
async def health_check():
    """Health check endpoint for email processing system"""
    try:
        queue = JobQueue(redis_url=settings.redis_url, queue_name="transaction_emails")
        stats = queue.get_queue_stats()
        
        return {
            "status": "healthy",
            "redis_connected": True,
            "queue_stats": stats,
            "timestamp": datetime.utcnow().isoformat()
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Service unhealthy: {str(e)}"
        )
