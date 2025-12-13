from pydantic import ConfigDict
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    model_config = ConfigDict(env_file=".env")
    app_name: str
    database_url: str
    secret_key: str
    algorithm: str
    access_token_expire_minutes: int
    gemini_api_key: str
    
    # Redis configuration
    redis_host: str = "redis"
    redis_port: int = 6379
    redis_db: int = 0
    redis_queue_name: str = "bank-txn-jobs"
    
    # IMAP configuration
    imap_host: str = "imap.gmail.com"
    imap_port: int = 993
    imap_username: str = ""
    imap_password: str = ""
    imap_mailbox: str = "INBOX"
    imap_poll_interval: int = 300
    
    # Worker configuration
    default_user_id: int = 1
    
    # Twilio configuration (optional - defaults to empty strings if not configured)
    twilio_account_sid: str = ""
    twilio_auth_token: str = ""
    twilio_whatsapp_from: str = ""
    twilio_content_sid: str = ""
    
    @property
    def redis_url(self) -> str:
        """Construct Redis URL from components"""
        return f"redis://{self.redis_host}:{self.redis_port}/{self.redis_db}"

settings = Settings()