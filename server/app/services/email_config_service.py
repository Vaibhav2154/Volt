"""
Email Configuration Service
Handles encryption/decryption of user email app passwords
"""
from cryptography.fernet import Fernet
from app.core.config import settings
import base64
import logging

logger = logging.getLogger(__name__)


class EmailConfigService:
    """Service for managing user email configurations"""
    
    def __init__(self):
        # Generate encryption key from settings secret_key
        # In production, use a dedicated encryption key
        key = base64.urlsafe_b64encode(settings.secret_key.encode()[:32].ljust(32, b'0'))
        self.cipher = Fernet(key)
    
    def encrypt_app_password(self, app_password: str) -> str:
        """Encrypt Gmail app password"""
        try:
            encrypted = self.cipher.encrypt(app_password.encode())
            return encrypted.decode()
        except Exception as e:
            logger.error(f"Failed to encrypt app password: {e}")
            raise ValueError("Failed to encrypt app password")
    
    def decrypt_app_password(self, encrypted_password: str) -> str:
        """Decrypt Gmail app password"""
        try:
            decrypted = self.cipher.decrypt(encrypted_password.encode())
            return decrypted.decode()
        except Exception as e:
            logger.error(f"Failed to decrypt app password: {e}")
            raise ValueError("Failed to decrypt app password")
    
    def validate_app_password_format(self, app_password: str) -> bool:
        """Validate Gmail app password format (16 characters)"""
        # Remove spaces and check length
        cleaned = app_password.replace(" ", "").replace("-", "")
        return len(cleaned) == 16 and cleaned.isalnum()
