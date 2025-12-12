"""
Multi-User Email Poller Service
Polls emails for all users who have enabled email parsing
"""
import logging
import time
from typing import List, Dict
from sqlalchemy.orm import Session

# Import database and base first
from app.database import SessionLocal, Base, engine

# Import all models to register them with SQLAlchemy
from app.models.user import User
from app.models.transactions import Transaction as TransactionModel
from app.models.behaviour import BehaviourModel

# Import services
from app.services.imap_poller import IMAPPoller
from app.services.email_parser import parse_bank_email
from app.services.job_queue import JobQueue
from app.services.email_config_service import EmailConfigService

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class MultiUserEmailPoller:
    """Polls emails for all users with email parsing enabled"""
    
    def __init__(
        self,
        redis_url: str,
        redis_queue_name: str = "transaction_emails",
        imap_server: str = "imap.gmail.com",
        imap_port: int = 993
    ):
        self.redis_url = redis_url
        self.redis_queue_name = redis_queue_name
        self.imap_server = imap_server
        self.imap_port = imap_port
        self.email_config_service = EmailConfigService()
        self.job_queue = JobQueue(redis_url=redis_url, queue_name=redis_queue_name)
    
    def get_enabled_users(self, db: Session) -> List[User]:
        """Get all users with email parsing enabled"""
        return db.query(User).filter(
            User.email_parsing_enabled == True,
            User.email_app_password.isnot(None)
        ).all()
    
    def poll_user_emails(self, user: User) -> List[Dict]:
        """Poll emails for a specific user"""
        try:
            # Decrypt app password
            app_password = self.email_config_service.decrypt_app_password(
                user.email_app_password
            )
            
            # Create IMAP poller for this user
            poller = IMAPPoller(
                imap_server=self.imap_server,
                imap_port=self.imap_port,
                email_address=user.email,
                email_password=app_password,
                poll_interval=300  # Not used in this context
            )
            
            # Connect and fetch emails
            if not poller.connect():
                logger.error(f"Failed to connect to IMAP for user: {user.email}")
                return []
            
            try:
                emails = poller.fetch_new_emails()
                logger.info(f"Fetched {len(emails)} emails for user: {user.email}")
                return emails
            finally:
                poller.disconnect()
                
        except Exception as e:
            logger.error(f"Error polling emails for user {user.email}: {e}")
            return []
    
    def process_user_emails(self, user: User, emails: List[Dict]):
        """Process emails for a specific user and enqueue jobs"""
        logger.info(f"Processing {len(emails)} emails for user: {user.email}")
        
        for email_data in emails:
            try:
                sender = email_data.get("sender", "")
                subject = email_data.get("subject", "")
                body = email_data.get("body", "")
                
                # Parse email for transaction data
                transaction_data = parse_bank_email(subject, body, sender)
                
                # Check if we extracted meaningful data
                if transaction_data.get("amount") or transaction_data.get("transactionId"):
                    # Add user_id to transaction data
                    job_data = {
                        "transaction": transaction_data,
                        "user_id": user.id,  # Important: link to user
                        "email_metadata": {
                            "sender": sender,
                            "subject": subject,
                            "date": email_data.get("date", ""),
                            "user_email": user.email
                        }
                    }
                    
                    job_id = self.job_queue.enqueue(
                        job_type="process_transaction",
                        data=job_data,
                        priority=1
                    )
                    
                    logger.info(
                        f"Enqueued job {job_id} for user {user.email}: "
                        f"{transaction_data.get('bankName', 'Unknown')} - "
                        f"₹{transaction_data.get('amount', 'N/A')}"
                    )
                else:
                    logger.debug(f"No transaction data in email: {subject}")
                    
            except Exception as e:
                logger.error(f"Error processing email for user {user.email}: {e}")
                continue
    
    def poll_all_users(self):
        """Poll emails for all enabled users"""
        db = SessionLocal()
        try:
            enabled_users = self.get_enabled_users(db)
            
            if not enabled_users:
                logger.info("No users with email parsing enabled")
                return
            
            logger.info(f"Polling emails for {len(enabled_users)} users")
            
            for user in enabled_users:
                try:
                    # Poll user's emails
                    emails = self.poll_user_emails(user)
                    
                    if emails:
                        # Process and enqueue
                        self.process_user_emails(user, emails)
                    
                except Exception as e:
                    logger.error(f"Error polling user {user.email}: {e}")
                    continue
                    
        finally:
            db.close()
    
    def start(self, poll_interval: int = 300):
        """Start continuous polling for all users"""
        logger.info(f"Starting Multi-User Email Poller (interval: {poll_interval}s)")
        
        while True:
            try:
                self.poll_all_users()
            except Exception as e:
                logger.error(f"Error in polling cycle: {e}")
            
            time.sleep(poll_interval)


if __name__ == "__main__":
    import os
    
    redis_host = os.getenv("REDIS_HOST", "localhost")
    redis_port = os.getenv("REDIS_PORT", "6379")
    redis_db = os.getenv("REDIS_DB", "0")
    redis_url = f"redis://{redis_host}:{redis_port}/{redis_db}"
    redis_queue_name = os.getenv("REDIS_QUEUE_NAME", "transaction_emails")
    poll_interval = int(os.getenv("IMAP_POLL_INTERVAL", "300"))
    
    poller = MultiUserEmailPoller(
        redis_url=redis_url,
        redis_queue_name=redis_queue_name
    )
    
    poller.start(poll_interval=poll_interval)
