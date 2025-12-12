"""
Transaction Worker Service
Processes transaction jobs from Redis queue and inserts into database
"""
import os
import logging
from typing import Dict, Any
from datetime import datetime
from decimal import Decimal
from sqlalchemy.orm import Session
from app.services.job_queue import JobQueue, Worker
from app.database import SessionLocal
from app.models.transactions import Transaction

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class TransactionWorker:
    """Worker to process transaction jobs and insert into database"""
    
    def __init__(self, redis_url: str, redis_queue_name: str = "transaction_emails", default_user_id: int = 1):
        self.job_queue = JobQueue(redis_url=redis_url, queue_name=redis_queue_name)
        self.worker = Worker(self.job_queue)
        self.default_user_id = default_user_id
        
        # Register handler
        self.worker.register_handler("process_transaction", self.process_transaction)
    
    def get_db(self) -> Session:
        """Get database session"""
        return SessionLocal()
    
    def convert_to_decimal(self, value: Any) -> Decimal:
        """Safely convert value to Decimal"""
        if value is None:
            return None
        if isinstance(value, Decimal):
            return value
        if isinstance(value, (int, float)):
            return Decimal(str(value))
        if isinstance(value, str):
            try:
                return Decimal(value)
            except:
                return None
        return None
    
    def parse_timestamp(self, timestamp_str: str) -> datetime:
        """Parse timestamp string to datetime"""
        if not timestamp_str:
            return None
        
        try:
            # Try ISO format first
            return datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
        except:
            pass
        
        # Try common formats
        formats = [
            "%Y-%m-%d %H:%M:%S",
            "%d-%m-%Y %H:%M:%S",
            "%d/%m/%Y %H:%M:%S",
            "%Y-%m-%dT%H:%M:%S",
        ]
        
        for fmt in formats:
            try:
                return datetime.strptime(timestamp_str, fmt)
            except:
                continue
        
        return None
    
    def process_transaction(self, job_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process transaction job - insert into database
        Args:
            job_data: Job data containing transaction, user_id, and email_metadata
        Returns:
            Result dict with transaction_id
        """
        transaction_data = job_data.get("transaction", {})
        email_metadata = job_data.get("email_metadata", {})
        user_id = job_data.get("user_id", self.default_user_id)  # Get user_id from job data
        
        logger.info(f"Processing transaction for user {user_id}: {transaction_data.get('transactionId', 'N/A')}")
        
        db = self.get_db()
        try:
            # Check if transaction already exists for this user
            existing = None
            if transaction_data.get("transactionId"):
                existing = db.query(Transaction).filter(
                    Transaction.transactionId == transaction_data["transactionId"],
                    Transaction.user_id == user_id
                ).first()
            
            if existing:
                logger.info(f"Transaction {transaction_data['transactionId']} already exists for user {user_id}, skipping")
                return {"status": "skipped", "transaction_id": existing.id, "reason": "duplicate"}
            
            # Parse timestamp
            timestamp = None
            if transaction_data.get("timestamp"):
                timestamp = self.parse_timestamp(transaction_data["timestamp"])
            
            # Create transaction record
            transaction = Transaction(
                user_id=user_id,  # Use user_id from job data
                amount=self.convert_to_decimal(transaction_data.get("amount")),
                merchant=transaction_data.get("merchant"),
                category=transaction_data.get("category"),
                upiId=transaction_data.get("upiId"),
                transactionId=transaction_data.get("transactionId"),
                timestamp=timestamp,
                type=transaction_data.get("type"),
                balance=self.convert_to_decimal(transaction_data.get("balance")),
                bankName=transaction_data.get("bankName"),
                accountNumber=transaction_data.get("accountNumber"),
                rawMessage=transaction_data.get("rawMessage", "")[:500]  # Limit to 500 chars
            )
            
            db.add(transaction)
            db.commit()
            db.refresh(transaction)
            
            logger.info(f"Successfully inserted transaction ID: {transaction.id} for user {user_id}")
            
            return {
                "status": "success",
                "transaction_id": transaction.id,
                "transaction_ref": transaction.transactionId,
                "amount": str(transaction.amount) if transaction.amount else None,
                "type": transaction.type,
                "bank": transaction.bankName
            }
            
        except Exception as e:
            db.rollback()
            logger.error(f"Database error: {e}")
            raise
        finally:
            db.close()
    
    def start(self, poll_interval: int = 1):
        """Start worker"""
        logger.info("Starting Transaction Worker")
        logger.info(f"Using default user_id: {self.default_user_id}")
        
        try:
            self.worker.start(poll_interval=poll_interval)
        except KeyboardInterrupt:
            logger.info("Worker stopped by user")
        except Exception as e:
            logger.error(f"Worker error: {e}")
            raise


def main():
    """Main entry point for worker service"""
    # Redis configuration
    redis_host = os.getenv("REDIS_HOST", "localhost")
    redis_port = int(os.getenv("REDIS_PORT", "6379"))
    redis_db = int(os.getenv("REDIS_DB", "0"))
    redis_queue_name = os.getenv("REDIS_QUEUE_NAME", "bank-txn-jobs")
    redis_url = f"redis://{redis_host}:{redis_port}/{redis_db}"
    
    default_user_id = int(os.getenv("DEFAULT_USER_ID", "1"))
    
    worker = TransactionWorker(
        redis_url=redis_url,
        redis_queue_name=redis_queue_name,
        default_user_id=default_user_id
    )
    
    worker.start(poll_interval=1)


if __name__ == "__main__":
    main()
