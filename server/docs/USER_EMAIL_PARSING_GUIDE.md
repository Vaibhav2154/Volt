# User-Based Email Parsing System - Implementation Summary

## Overview
The email parsing system has been upgraded to work on a per-user basis. Each user can enable email parsing by providing their Gmail app password and giving consent.

## Key Features

### 1. User Model Updates
**File**: `app/models/user.py`
- Added `email_app_password` column to store encrypted Gmail app passwords
- Added `email_parsing_enabled` boolean flag to control parsing per user

### 2. Email Configuration Service
**File**: `app/services/email_config_service.py`
- Encrypts/decrypts Gmail app passwords using Fernet encryption
- Validates app password format (16 characters)
- Uses the application's secret key for encryption

### 3. Email Configuration API Endpoints
**File**: `app/routers/email_config_router.py`

#### `/email-config/setup-app-password` [POST]
Setup Gmail app password for authenticated user
```json
{
  "app_password": "abcd efgh ijkl mnop",
  "consent": true
}
```
Response:
```json
{
  "status": "success",
  "email_parsing_enabled": true,
  "message": "Email parsing enabled for user@gmail.com"
}
```

#### `/email-config/status` [GET]
Get email parsing status for current user
```json
{
  "email_parsing_enabled": true,
  "email_address": "user@gmail.com",
  "has_app_password": true,
  "message": "Email parsing is active"
}
```

#### `/email-config/disable` [POST]
Disable email parsing and remove app password
```json
{
  "confirm": true
}
```

#### `/email-config/update-app-password` [POST]
Update Gmail app password (same as setup)

### 4. Multi-User Email Poller
**File**: `app/services/multi_user_email_poller.py`

- Polls emails for ALL users who have `email_parsing_enabled = true`
- Fetches each user's email using their stored (encrypted) app password
- Links transactions to the correct user via `user_id`
- Runs continuously in Docker container
- Default polling interval: 300 seconds (5 minutes)

### 5. Updated Transaction Worker
**File**: `app/services/transaction_worker.py`

- Now uses `user_id` from job data instead of hardcoded default
- Checks for duplicate transactions per user
- Links all transactions to the correct user account

## How It Works

### User Flow:
1. **User registers/logs in** to the application
2. **User navigates to email parsing settings**
3. **User provides Gmail app password** and gives consent
4. **System encrypts and stores** the app password
5. **Email parsing automatically starts** for this user

### Background Process:
1. **Multi-User Email Poller** runs every 5 minutes
2. **Queries database** for users with `email_parsing_enabled = true`
3. **For each user**:
   - Decrypts their app password
   - Connects to their Gmail via IMAP
   - Fetches new transaction emails
   - Parses emails and enqueues jobs with `user_id`
4. **Transaction Worker** processes jobs and inserts to database with correct `user_id`

## Security Features

- ✅ **Encrypted storage** of Gmail app passwords using Fernet encryption
- ✅ **User consent required** before enabling email parsing
- ✅ **Authentication required** for all email config endpoints (OAuth2 JWT)
- ✅ **Per-user isolation** - users only see their own transactions
- ✅ **Secure password handling** - passwords never logged or exposed

## Database Migration

**File**: `migrations/versions/add_email_parsing.py`

Run migration to add new columns:
```bash
alembic upgrade head
```

## Docker Configuration

### Updated Services:
- **email_poller**: Now runs `multi_user_email_poller.py` with full database access
- **api**: Includes new `/email-config` endpoints
- **transaction_worker**: Uses `user_id` from job data

### Environment Variables (email_poller):
```env
DATABASE_URL=postgresql://...
SECRET_KEY=your-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
APP_NAME=Kronyx
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_DB=0
REDIS_QUEUE_NAME=transaction_emails
IMAP_POLL_INTERVAL=300
```

## API Testing

### Setup App Password:
```bash
curl -X POST http://localhost:8000/email-config/setup-app-password \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "app_password": "your 16 char password",
    "consent": true
  }'
```

### Check Status:
```bash
curl http://localhost:8000/email-config/status \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Disable Parsing:
```bash
curl -X POST http://localhost:8000/email-config/disable \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"confirm": true}'
```

## Dependencies Added
- `cryptography==44.0.0` - For Fernet encryption

## Next Steps for Production

1. **Use dedicated encryption key** instead of deriving from SECRET_KEY
2. **Add rate limiting** on email config endpoints
3. **Implement email verification** before allowing email parsing
4. **Add audit logging** for email parsing enable/disable events
5. **Monitor IMAP connection failures** and notify users
6. **Add user notifications** for failed email parsing
7. **Implement backup/recovery** for encrypted app passwords
8. **Add admin dashboard** to monitor email parsing across all users

## User Instructions

### How to Get Gmail App Password:
1. Go to Google Account settings
2. Enable 2-Factor Authentication (required)
3. Go to Security > 2-Step Verification > App passwords
4. Generate new app password for "Mail"
5. Copy the 16-character password
6. Paste into the app (spaces will be removed automatically)

## Transaction Processing Flow

```
User Email (Gmail)
    ↓
Multi-User Email Poller (every 5 min)
    ↓
Email Parser (extract transaction data)
    ↓
Redis Job Queue (with user_id)
    ↓
Transaction Worker
    ↓
PostgreSQL Database (linked to correct user)
```

## Monitoring

- Email Poller logs show polling activity per user
- Transaction Worker logs show successful insertions with user_id
- API endpoints provide real-time status
- Redis queue stats available via `/email-transactions/health`
