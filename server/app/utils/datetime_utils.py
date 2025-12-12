"""
Timezone-aware datetime utilities for consistent timestamp handling.

All timestamps should be stored in UTC and converted to timezone-aware datetimes.
"""
from datetime import datetime, timezone
from typing import Optional


def utc_now() -> datetime:
    """
    Get current UTC time as timezone-aware datetime.
    
    Returns:
        Timezone-aware datetime in UTC
    """
    return datetime.now(timezone.utc)


def ensure_utc(dt: Optional[datetime]) -> Optional[datetime]:
    """
    Ensure a datetime is timezone-aware and in UTC.
    
    If naive, assumes it's already UTC and adds timezone info.
    If aware but not UTC, converts to UTC.
    
    Args:
        dt: Datetime to normalize (can be None, naive, or aware)
        
    Returns:
        Timezone-aware datetime in UTC, or None if input is None
    """
    if dt is None:
        return None
    
    # If naive, assume UTC and make aware
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    
    # If aware but not UTC, convert to UTC
    return dt.astimezone(timezone.utc)


def safe_isoformat(dt: Optional[datetime]) -> Optional[str]:
    """
    Safely convert datetime to ISO format string.
    
    Args:
        dt: Datetime to format
        
    Returns:
        ISO format string or None if input is None
    """
    if dt is None:
        return None
    
    # Ensure UTC before formatting
    dt_utc = ensure_utc(dt)
    return dt_utc.isoformat()


def safe_fromisoformat(iso_string: Optional[str]) -> Optional[datetime]:
    """
    Safely parse ISO format string to timezone-aware datetime.
    
    Args:
        iso_string: ISO format datetime string
        
    Returns:
        Timezone-aware datetime in UTC, or None if input is None
    """
    if not iso_string:
        return None
    
    try:
        dt = datetime.fromisoformat(iso_string)
        return ensure_utc(dt)
    except (ValueError, TypeError):
        return None
