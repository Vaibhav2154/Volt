"""
Custom Python Job Queue System using Redis
Simple, lightweight job queue without external dependencies
"""
import json
import time
import uuid
import logging
from typing import Dict, Any, Optional, Callable
from datetime import datetime
import redis

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class JobQueue:
    """Simple job queue using Redis"""
    
    def __init__(self, redis_url: str, queue_name: str = "email_jobs"):
        """
        Initialize job queue
        Args:
            redis_url: Redis connection URL (e.g., redis://localhost:6379/0)
            queue_name: Name of the queue
        """
        # Configure SSL for Heroku Redis (uses self-signed certificates)
        import ssl
        ssl_params = {}
        if redis_url.startswith('rediss://'):  # SSL Redis connection
            ssl_params = {
                'ssl_cert_reqs': ssl.CERT_NONE,  # Don't verify SSL certificates (Heroku uses self-signed)
                'ssl_check_hostname': False
            }
        
        self.redis_client = redis.from_url(
            redis_url, 
            decode_responses=True,
            **ssl_params
        )
        self.queue_name = queue_name
        self.processing_queue = f"{queue_name}:processing"
        self.failed_queue = f"{queue_name}:failed"
        self.job_data_prefix = f"{queue_name}:job:"
        
    def enqueue(self, job_type: str, data: Dict[str, Any], priority: int = 0) -> str:
        """
        Enqueue a new job
        Args:
            job_type: Type of job (e.g., 'parse_email', 'process_transaction')
            data: Job data as dictionary
            priority: Job priority (higher = processed first)
        Returns:
            job_id: Unique job identifier
        """
        job_id = str(uuid.uuid4())
        
        job = {
            "job_id": job_id,
            "job_type": job_type,
            "data": data,
            "status": "queued",
            "created_at": datetime.utcnow().isoformat(),
            "priority": priority,
            "attempts": 0,
            "max_attempts": 3
        }
        
        # Store job data
        job_key = f"{self.job_data_prefix}{job_id}"
        self.redis_client.set(job_key, json.dumps(job))
        
        # Add to queue with priority
        self.redis_client.zadd(self.queue_name, {job_id: -priority})
        
        logger.info(f"Enqueued job {job_id} of type {job_type}")
        return job_id
    
    def dequeue(self, timeout: int = 0) -> Optional[Dict[str, Any]]:
        """
        Dequeue next job (blocking)
        Args:
            timeout: Timeout in seconds (0 = wait forever)
        Returns:
            Job dictionary or None if timeout
        """
        # Get highest priority job (lowest score due to negative priority)
        result = self.redis_client.zpopmin(self.queue_name, 1)
        
        if not result:
            if timeout > 0:
                # Use blocking pop with timeout
                time.sleep(min(1, timeout))
                return self.dequeue(timeout - 1)
            return None
        
        job_id = result[0][0]
        job_key = f"{self.job_data_prefix}{job_id}"
        
        # Get job data
        job_data = self.redis_client.get(job_key)
        if not job_data:
            logger.warning(f"Job data not found for {job_id}")
            return None
        
        job = json.loads(job_data)
        
        # Move to processing queue
        job["status"] = "processing"
        job["started_at"] = datetime.utcnow().isoformat()
        self.redis_client.set(job_key, json.dumps(job))
        self.redis_client.sadd(self.processing_queue, job_id)
        
        logger.info(f"Dequeued job {job_id}")
        return job
    
    def complete_job(self, job_id: str, result: Optional[Dict[str, Any]] = None):
        """Mark job as completed"""
        job_key = f"{self.job_data_prefix}{job_id}"
        job_data = self.redis_client.get(job_key)
        
        if job_data:
            job = json.loads(job_data)
            job["status"] = "completed"
            job["completed_at"] = datetime.utcnow().isoformat()
            if result:
                job["result"] = result
            
            self.redis_client.set(job_key, json.dumps(job), ex=86400)  # Keep for 24h
            self.redis_client.srem(self.processing_queue, job_id)
            logger.info(f"Job {job_id} completed")
    
    def fail_job(self, job_id: str, error: str, retry: bool = True):
        """Mark job as failed"""
        job_key = f"{self.job_data_prefix}{job_id}"
        job_data = self.redis_client.get(job_key)
        
        if not job_data:
            return
        
        job = json.loads(job_data)
        job["attempts"] = job.get("attempts", 0) + 1
        job["last_error"] = error
        job["last_attempt_at"] = datetime.utcnow().isoformat()
        
        # Retry logic
        if retry and job["attempts"] < job.get("max_attempts", 3):
            job["status"] = "queued"
            # Re-enqueue with exponential backoff
            delay = 2 ** job["attempts"]
            job["retry_after"] = (datetime.utcnow().timestamp() + delay)
            
            self.redis_client.set(job_key, json.dumps(job))
            self.redis_client.srem(self.processing_queue, job_id)
            
            # Re-add to queue with same priority
            priority = job.get("priority", 0)
            self.redis_client.zadd(self.queue_name, {job_id: -priority})
            logger.warning(f"Job {job_id} failed, retrying (attempt {job['attempts']})")
        else:
            # Max attempts reached, move to failed queue
            job["status"] = "failed"
            job["failed_at"] = datetime.utcnow().isoformat()
            
            self.redis_client.set(job_key, json.dumps(job), ex=604800)  # Keep for 7 days
            self.redis_client.srem(self.processing_queue, job_id)
            self.redis_client.sadd(self.failed_queue, job_id)
            logger.error(f"Job {job_id} permanently failed after {job['attempts']} attempts")
    
    def get_job_status(self, job_id: str) -> Optional[Dict[str, Any]]:
        """Get job status and data"""
        job_key = f"{self.job_data_prefix}{job_id}"
        job_data = self.redis_client.get(job_key)
        
        if job_data:
            return json.loads(job_data)
        return None
    
    def get_queue_stats(self) -> Dict[str, int]:
        """Get queue statistics"""
        return {
            "queued": self.redis_client.zcard(self.queue_name),
            "processing": self.redis_client.scard(self.processing_queue),
            "failed": self.redis_client.scard(self.failed_queue)
        }
    
    def clear_queue(self):
        """Clear all jobs from queue (use with caution)"""
        self.redis_client.delete(self.queue_name)
        self.redis_client.delete(self.processing_queue)
        logger.warning("Queue cleared")


class Worker:
    """Worker to process jobs from queue"""
    
    def __init__(self, queue: JobQueue):
        self.queue = queue
        self.handlers: Dict[str, Callable] = {}
        self.running = False
    
    def register_handler(self, job_type: str, handler: Callable):
        """
        Register a handler function for a job type
        Handler should accept job data dict and return result dict or raise exception
        """
        self.handlers[job_type] = handler
        logger.info(f"Registered handler for job type: {job_type}")
    
    def process_job(self, job: Dict[str, Any]):
        """Process a single job"""
        job_id = job["job_id"]
        job_type = job["job_type"]
        
        handler = self.handlers.get(job_type)
        if not handler:
            error = f"No handler registered for job type: {job_type}"
            logger.error(error)
            self.queue.fail_job(job_id, error, retry=False)
            return
        
        try:
            logger.info(f"Processing job {job_id} of type {job_type}")
            result = handler(job["data"])
            self.queue.complete_job(job_id, result)
        except Exception as e:
            error = f"Job processing failed: {str(e)}"
            logger.error(f"Job {job_id} error: {error}")
            self.queue.fail_job(job_id, error)
    
    def start(self, poll_interval: int = 1):
        """Start worker to process jobs"""
        self.running = True
        logger.info("Worker started")
        
        while self.running:
            try:
                job = self.queue.dequeue(timeout=poll_interval)
                
                if job:
                    self.process_job(job)
                else:
                    time.sleep(poll_interval)
                    
            except KeyboardInterrupt:
                logger.info("Worker interrupted by user")
                break
            except Exception as e:
                logger.error(f"Worker error: {e}")
                time.sleep(poll_interval)
        
        logger.info("Worker stopped")
    
    def stop(self):
        """Stop worker"""
        self.running = False
