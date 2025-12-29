# Volt (Kronyx)

<div align="center">

**A comprehensive AI-powered finance and expense tracker designed for modern users, especially gig workers and freelancers with variable income**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/Python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.123+-green.svg)](https://fastapi.tiangolo.com/)

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [API Documentation](#api-documentation)
- [Features in Detail](#features-in-detail)
- [Deployment](#deployment)
- [Development](#development)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

---

## 🌟 Overview

Volt (also known as Kronyx) is a sophisticated financial management platform that combines intelligent expense tracking with AI-powered insights. Built specifically with gig workers, freelancers, and individuals with variable income in mind, it provides personalized financial recommendations based on your unique spending patterns and income volatility.

### What Makes Volt Different?

- **Income Volatility Tracking**: Specifically designed for freelancers and gig workers with irregular income
- **AI-Powered Insights**: Uses Pydantic AI and Google Gemini for intelligent financial analysis
- **Email Transaction Parsing**: Automatically extracts transaction data from bank emails
- **WhatsApp Integration**: Get financial insights and updates via WhatsApp
- **Gamification**: Earn points and achievements for good financial habits
- **Health Score**: Comprehensive financial health monitoring
- **Lean Week Predictions**: AI predicts upcoming lean periods to help you plan better

---

## 🚀 Key Features

### 💰 Advanced Income & Expense Tracking

- **Automated Transaction Detection**: Parse transactions from bank emails automatically
- **Income Volatility Analysis**: Track income variability with Welford's algorithm for numerical stability
- **Expense Categorization**: Smart categorization with custom categories
- **Credit/Debit Tracking**: Separate tracking for income and expenses
- **Multi-source Income**: Track income from multiple clients/sources
- **Business vs Personal Separation**: Distinguish between business and personal transactions

### 📊 Intelligent Financial Insights

- **Behavior Pattern Analysis**: Understand your spending habits with data-driven insights
- **Spending Flexibility Analysis**: Identify which expenses are flexible vs. fixed
- **Impulse Score Tracking**: Monitor impulsive spending behavior
- **Category-wise Statistics**: Detailed breakdown by expense categories
- **Emergency Fund Recommendations**: Personalized based on income volatility (3-6 months)
- **Income Source Diversity**: Track client diversity for risk assessment

### 🎯 Goal Management

- **Financial Goals**: Set and track savings goals
- **Goal Contributions**: Monitor progress toward financial objectives
- **Goal Achievement Tracking**: Visual progress indicators

### 🎮 Gamification System

- **Points & Achievements**: Earn rewards for positive financial behaviors
- **Streaks**: Maintain daily engagement streaks
- **Leaderboards**: Compare progress (optional)
- **Challenges**: Complete financial challenges for bonus rewards

### 🏥 Financial Health Score

- **Comprehensive Health Metrics**: Overall financial health assessment
- **Score Breakdown**: Detailed component analysis
- **Improvement Recommendations**: Actionable advice to boost your score
- **Trend Tracking**: Monitor health score over time

### 🤖 AI-Powered Features

- **Lean Week Predictions**: AI forecasts upcoming low-income periods
- **Personalized Recommendations**: Context-aware spending advice
- **Risk Warnings**: Proactive alerts for income volatility and spending issues
- **Smart Insights**: AI-generated financial insights using Google Gemini

### 📧 Email & Messaging Integration

- **Email Transaction Parser**: Automatically extract transactions from bank emails
- **WhatsApp Notifications**: Receive insights via WhatsApp (Twilio integration)
- **Real-time Updates**: Instant notifications for important events
- **Email Configuration Management**: Configure email sources per user

### 📱 Cross-Platform Support

- **Flutter Mobile App**: Native iOS and Android applications
- **RESTful API**: Comprehensive backend API for all operations
- **Real-time Sync**: Data synchronization across devices

---

## 🛠️ Tech Stack

### Frontend - Mobile Application

- **Flutter 3.10+**: Cross-platform mobile framework for iOS and Android
- **Flutter Bloc**: State management with BLoC pattern
- **Dio**: HTTP client for API communication
- **Get It**: Dependency injection
- **Flutter Secure Storage**: Secure local data storage
- **Shared Preferences**: Local configuration storage
- **Dartz**: Functional programming utilities
- **Equatable**: Value equality comparisons

### Backend - Server

#### Core Framework
- **FastAPI 0.123+**: Modern, high-performance Python web framework
- **Uvicorn**: Lightning-fast ASGI server
- **Pydantic**: Data validation and settings management
- **SQLAlchemy 2.0**: SQL toolkit and ORM
- **Alembic**: Database migrations

#### AI & Intelligence
- **Pydantic AI**: AI-powered data analysis framework
- **Google Gemini**: LLM for intelligent insights and recommendations
- **Welford's Algorithm**: Numerically stable variance computation for income volatility

#### Database & Caching
- **PostgreSQL**: Primary relational database
- **Redis**: In-memory data store for job queues and caching
- **Supabase**: Backend-as-a-Service (optional for additional features)

#### Authentication & Security
- **JWT (PyJWT)**: Token-based authentication
- **OAuth2**: Secure authentication flows
- **Passlib/PWDLib**: Password hashing
- **Python-Multipart**: File upload support

#### External Integrations
- **Twilio**: WhatsApp messaging integration
- **IMAP Client**: Email transaction parsing
- **Google Auth**: Authentication with Google services

#### Background Processing
- **Redis Queue**: Asynchronous job processing
- **Email Poller**: Background email monitoring service
- **Transaction Worker**: Async transaction processing

#### Development & Deployment
- **Docker & Docker Compose**: Containerization
- **Heroku**: Cloud deployment platform
- **Pytest**: Testing framework
- **Python-Dotenv**: Environment variable management

---

## 📁 Project Structure

```
volt/
├── mobile/                          # Flutter mobile application
│   ├── lib/
│   │   ├── core/                   # Core utilities, constants, errors
│   │   ├── features/               # Feature modules
│   │   │   ├── auth/              # Authentication feature
│   │   │   ├── transactions/      # Transaction management
│   │   │   ├── insights/          # Financial insights
│   │   │   ├── goals/             # Goal tracking
│   │   │   └── profile/           # User profile
│   │   ├── init_dependencies.dart # Dependency injection setup
│   │   └── main.dart              # Application entry point
│   ├── android/                    # Android-specific configuration
│   ├── ios/                        # iOS-specific configuration
│   ├── assets/                     # Images, fonts, and other assets
│   ├── test/                       # Unit and widget tests
│   └── pubspec.yaml               # Flutter dependencies
│
├── server/                         # FastAPI backend server
│   ├── app/
│   │   ├── main.py                # FastAPI application entry point
│   │   ├── database.py            # Database setup and connections
│   │   ├── oauth2.py              # JWT authentication logic
│   │   ├── core/
│   │   │   └── config.py          # Configuration management
│   │   ├── models/                # SQLAlchemy database models
│   │   │   ├── user.py           # User model
│   │   │   ├── transactions.py   # Transaction model
│   │   │   ├── behaviour.py      # Behavior analysis model
│   │   │   ├── goal.py           # Goal models
│   │   │   └── gamification.py   # Gamification models
│   │   ├── schemas/               # Pydantic request/response schemas
│   │   ├── routers/               # API route handlers
│   │   │   ├── user_router.py
│   │   │   ├── transactions_router.py
│   │   │   ├── goal_router.py
│   │   │   ├── email_transactions.py
│   │   │   ├── gamification_router.py
│   │   │   ├── health_score_router.py
│   │   │   ├── lean_week_router.py
│   │   │   └── twilio_webhook.py
│   │   ├── services/              # Business logic services
│   │   │   ├── behavior_engine.py      # Income/expense analysis
│   │   │   ├── insight_formatter_v2.py # Insight generation
│   │   │   ├── email_parser.py         # Email parsing logic
│   │   │   └── lean_week_predictor.py  # AI predictions
│   │   ├── api/
│   │   │   └── simulation_routes.py    # Insights API
│   │   └── utils/                 # Utility functions
│   ├── migrations/                # Alembic database migrations
│   ├── tests/                     # Backend tests
│   ├── docs/                      # Comprehensive documentation
│   │   ├── ARCHITECTURE_DIAGRAM.md
│   │   ├── BACKEND.md
│   │   ├── INSIGHTS.md
│   │   ├── FREELANCER_ENHANCEMENTS.md
│   │   ├── GAMIFICATION.md
│   │   ├── LEAN_WEEK_PREDICTOR_README.md
│   │   └── USER_EMAIL_PARSING_GUIDE.md
│   ├── Dockerfile                 # Main API container
│   ├── Dockerfile.worker          # Transaction worker container
│   ├── Dockerfile.poller          # Email poller container
│   ├── docker-compose.yml         # Multi-container setup
│   ├── requirements.txt           # Python dependencies
│   ├── run.py                     # Development server startup
│   └── alembic.ini               # Migration configuration
│
├── HEROKU_DEPLOYMENT.md           # Heroku deployment guide
├── WELFORD.md                     # Welford's algorithm documentation
├── WHATSAPP_INTEGRATION.md        # WhatsApp setup guide
├── LICENSE                        # MIT License
└── README.md                      # This file
```

---

## 🚦 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

#### For Backend Development
- **Python 3.8+** - [Download](https://www.python.org/downloads/)
- **PostgreSQL 12+** - [Download](https://www.postgresql.org/download/)
- **Redis** (optional for local development) - [Download](https://redis.io/download)
- **Git** - [Download](https://git-scm.com/downloads/)

#### For Mobile Development
- **Flutter SDK 3.10+** - [Installation Guide](https://docs.flutter.dev/get-started/install)
- **Android Studio** (for Android development) - [Download](https://developer.android.com/studio)
- **Xcode** (for iOS development, macOS only) - [Mac App Store](https://apps.apple.com/app/xcode/id497799835)

#### Optional but Recommended
- **Docker & Docker Compose** - [Download](https://www.docker.com/products/docker-desktop) (easiest way to run everything)
- **Heroku CLI** - [Download](https://devcenter.heroku.com/articles/heroku-cli) (for deployment)

### Quick Start with Docker (Recommended)

The fastest way to get Volt up and running is with Docker Compose:

1. **Clone the repository**
   ```bash
   git clone https://github.com/Vaibhav2154/Volt.git
   cd Volt/server
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start all services**
   ```bash
   docker-compose up --build
   ```

   This will start:
   - FastAPI backend on `http://localhost:8000`
   - PostgreSQL database
   - Redis queue
   - Email poller service
   - Transaction worker

4. **Access the API**
   - Swagger UI: `http://localhost:8000/docs`
   - ReDoc: `http://localhost:8000/redoc`

### Backend Setup (Manual)

If you prefer to run the backend without Docker:

1. **Navigate to server directory**
   ```bash
   cd server
   ```

2. **Create and activate virtual environment**
   ```bash
   # On Linux/macOS
   python3 -m venv venv
   source venv/bin/activate

   # On Windows
   python -m venv venv
   venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up PostgreSQL database**
   ```bash
   # Create database
   createdb volt_db
   
   # Or using psql
   psql -U postgres -c "CREATE DATABASE volt_db;"
   ```

5. **Configure environment variables**
   ```bash
   cp .env.example .env
   ```

   Edit `.env` and set:
   ```env
   APP_NAME=Kronyx
   DATABASE_URL=postgresql://username:password@localhost/volt_db
   SECRET_KEY=your-secret-key-here-generate-a-strong-one
   ALGORITHM=HS256
   ACCESS_TOKEN_EXPIRE_MINUTES=30
   
   # Optional: Redis configuration
   REDIS_HOST=localhost
   REDIS_PORT=6379
   REDIS_DB=0
   
   # Optional: Gemini AI
   GEMINI_API_KEY=your-gemini-api-key
   
   # Optional: Twilio WhatsApp
   TWILIO_ACCOUNT_SID=your-twilio-sid
   TWILIO_AUTH_TOKEN=your-twilio-token
   TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
   ```

6. **Run database migrations**
   ```bash
   alembic upgrade head
   ```

7. **Start the development server**
   ```bash
   # Using uvicorn directly
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   
   # Or using the run script
   python run.py
   ```

   The API will be available at `http://localhost:8000`

### Mobile App Setup

1. **Navigate to mobile directory**
   ```bash
   cd mobile
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**
   
   Update the API base URL in your configuration to point to your backend:
   - For local development: `http://localhost:8000` (Android emulator may need `http://10.0.2.2:8000`)
   - For production: Your deployed backend URL

4. **Run the application**
   ```bash
   # Check connected devices
   flutter devices
   
   # Run on connected device/emulator
   flutter run
   
   # Run in debug mode with hot reload
   flutter run --debug
   
   # Build for release
   flutter build apk        # Android
   flutter build ios        # iOS (macOS only)
   ```

### Background Services (Optional)

For full functionality, you may want to run background services:

#### Email Poller (monitors bank emails)
```bash
python -m app.services.email_poller
```

#### Transaction Worker (processes queued transactions)
```bash
python -m app.services.transaction_worker
```

**Note**: These services require Redis to be running.

---

## 📚 API Documentation

### Interactive Documentation

Once the server is running, comprehensive interactive API documentation is available:

- **Swagger UI**: `http://localhost:8000/docs`
  - Interactive API testing interface
  - Try out endpoints directly from your browser
  - View request/response schemas
  
- **ReDoc**: `http://localhost:8000/redoc`
  - Clean, three-panel documentation
  - Easy to navigate and search
  - Downloadable OpenAPI specification

### Main API Endpoints

#### Authentication
```
POST   /users/signup          # Create new user account
POST   /users/login           # Login and get JWT token
GET    /users/me              # Get current user info
```

#### Transactions
```
GET    /transactions/         # List user transactions
POST   /transactions/         # Create new transaction
GET    /transactions/{id}     # Get transaction details
PUT    /transactions/{id}     # Update transaction
DELETE /transactions/{id}     # Delete transaction
POST   /transactions/ocr      # Extract transaction from image
```

#### Financial Insights
```
GET    /users/{user_id}/insights/dashboard      # Main insights dashboard
GET    /api/users/{user_id}/income-stats        # Income statistics
GET    /api/users/{user_id}/lean-week-prediction # AI lean week forecast
```

#### Goals
```
GET    /goals/                # List user goals
POST   /goals/                # Create new goal
PUT    /goals/{id}            # Update goal
POST   /goals/{id}/contribute # Add contribution to goal
```

#### Email Integration
```
GET    /email-config/         # Get email configuration
POST   /email-config/         # Set email configuration
POST   /email-transactions/poll # Trigger email polling
```

#### Gamification
```
GET    /gamification/points   # Get user points
GET    /gamification/achievements # Get achievements
GET    /gamification/streaks  # Get streak information
```

#### Health Score
```
GET    /health-score/{user_id} # Get financial health score
```

#### WhatsApp Integration
```
POST   /whatsapp/webhook      # Twilio webhook for WhatsApp messages
```

### Authentication

All protected endpoints require a Bearer token:

```bash
# Login to get token
curl -X POST http://localhost:8000/users/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "yourpassword"}'

# Use token in subsequent requests
curl -X GET http://localhost:8000/users/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 🎯 Features in Detail

### Income Volatility Tracking

Volt uses **Welford's online algorithm** for numerically stable variance computation, specifically designed for freelancers and gig workers with irregular income streams.

**What it tracks:**
- Mean monthly income
- Income standard deviation
- Volatility coefficient (CV = std_dev/mean)
- Payment frequency and gaps
- Client diversity (number of income sources)
- Business vs personal income separation

**Why it matters:**
- Freelancers need to know if their income is HIGH (>40%), MODERATE (30-40%), or STABLE (<30%)
- Higher volatility = larger emergency fund needed (6 months vs 3 months)
- Identifies risky client concentration

**Technical Implementation:**
See [WELFORD.md](WELFORD.md) for the mathematical details of the algorithm.

### Email Transaction Parsing

Automatically extract transaction data from bank notification emails:

**Supported Banks:**
- ICICI Bank
- HDFC Bank
- SBI (State Bank of India)
- Axis Bank
- And more...

**How it works:**
1. Configure your email credentials in the app
2. Email poller service monitors your inbox
3. Transactions are automatically parsed and categorized
4. You can review and approve parsed transactions

**Features:**
- Automatic merchant detection
- Amount and currency extraction
- Transaction type detection (debit/credit)
- Duplicate detection
- Manual review and editing

See [server/docs/USER_EMAIL_PARSING_GUIDE.md](server/docs/USER_EMAIL_PARSING_GUIDE.md) for detailed setup.

### AI-Powered Lean Week Prediction

Predict upcoming low-income periods using machine learning:

**What it predicts:**
- Probability of upcoming lean weeks
- Expected income ranges
- Risk levels
- Recommended actions

**Factors analyzed:**
- Historical income patterns
- Payment frequency
- Client diversity
- Seasonal trends
- Current spending rate

**Use cases:**
- Plan major purchases during high-income periods
- Build buffer savings before predicted lean periods
- Adjust discretionary spending proactively

See [server/docs/LEAN_WEEK_PREDICTOR_README.md](server/docs/LEAN_WEEK_PREDICTOR_README.md) for technical details.

### Behavior Analysis Engine

Comprehensive spending behavior analysis:

**Category Statistics:**
- Monthly average per category
- Transaction frequency
- Spending trends
- Reliability scores

**Spending Flexibility (Elasticity):**
- Identifies which expenses are flexible vs. fixed
- Helps prioritize budget cuts when needed
- Categories ranked by flexibility

**Impulse Score:**
- Detects impulsive spending patterns
- Tracks unusual transaction times
- Monitors high-frequency small purchases

**Monthly Patterns:**
- Income statistics
- Expense patterns
- Savings rate
- Month-over-month trends

See [server/docs/BACKEND.md](server/docs/BACKEND.md) for implementation details.

### Personalized Insights

AI-generated financial recommendations:

**Insight Types:**
1. **Income Insights**
   - Volatility warnings
   - Emergency fund recommendations
   - Income diversification advice

2. **Spending Insights**
   - Category-specific recommendations
   - Flexible vs fixed expense analysis
   - Impulse spending warnings

3. **Goal Insights**
   - Progress tracking
   - Achievement predictions
   - Optimization suggestions

4. **Risk Warnings**
   - High volatility alerts
   - Low balance warnings
   - Unusual spending patterns

**Powered by:**
- Google Gemini for natural language generation
- Pydantic AI for structured data analysis
- Custom behavior analysis algorithms

See [server/docs/INSIGHTS.md](server/docs/INSIGHTS.md) for the complete insights system.

### Gamification System

Make financial management engaging:

**Points System:**
- Earn points for good financial behaviors
- Track daily, weekly, and monthly progress
- Compete with yourself or others (optional)

**Achievements:**
- Unlock badges for milestones
- Track achievement progress
- Share accomplishments

**Streaks:**
- Daily engagement tracking
- Longest streak records
- Streak recovery mechanics

**Events Tracked:**
- Transaction logging
- Goal contributions
- Budget adherence
- Savings milestones

See [server/docs/GAMIFICATION.md](server/docs/GAMIFICATION.md) for the complete gamification system.

### WhatsApp Integration

Get financial insights directly in WhatsApp:

**Features:**
- Daily/weekly summary messages
- Transaction notifications
- Balance updates
- Goal progress updates
- AI-powered Q&A about your finances

**Setup:**
Requires Twilio account with WhatsApp Business API access.
See [WHATSAPP_INTEGRATION.md](server/WHATSAPP_INTEGRATION.md) for setup instructions.

### Financial Health Score

Comprehensive health monitoring:

**Components:**
- Savings rate
- Debt-to-income ratio
- Emergency fund adequacy
- Spending consistency
- Income stability
- Goal progress

**Score Breakdown:**
- Overall score (0-100)
- Component scores
- Improvement recommendations
- Historical trends

**Use Cases:**
- Track financial wellness over time
- Identify areas for improvement
- Measure progress toward financial goals

---

## 🚀 Deployment

### Docker Deployment

The recommended deployment method using Docker:

1. **Build Docker images**
   ```bash
   docker-compose build
   ```

2. **Run in production mode**
   ```bash
   docker-compose up -d
   ```

3. **Scale services**
   ```bash
   docker-compose up -d --scale worker=2 --scale poller=1
   ```

**Services:**
- `api`: Main FastAPI application
- `redis`: Redis queue and cache
- `email_poller`: Email monitoring service
- `transaction_worker`: Transaction processing worker

### Heroku Deployment

Detailed Heroku deployment instructions available in [HEROKU_DEPLOYMENT.md](HEROKU_DEPLOYMENT.md).

**Quick Start:**

1. **Install Heroku CLI**
   ```bash
   heroku login
   ```

2. **Create Heroku app**
   ```bash
   cd server
   heroku create your-app-name
   ```

3. **Add required add-ons**
   ```bash
   # PostgreSQL database
   heroku addons:create heroku-postgresql:essential-0
   
   # Redis for queues
   heroku addons:create heroku-redis:mini
   ```

4. **Set environment variables**
   ```bash
   heroku config:set SECRET_KEY="your-secret-key"
   heroku config:set GEMINI_API_KEY="your-gemini-key"
   # ... other config vars
   ```

5. **Deploy**
   ```bash
   git push heroku main
   ```

6. **Run migrations**
   ```bash
   heroku run alembic upgrade head
   ```

7. **Scale dynos**
   ```bash
   heroku ps:scale web=1 worker=1 poller=1
   ```

**Process Types:**
- `web`: API server
- `worker`: Transaction processor
- `poller`: Email polling service
- `release`: Auto-run migrations on deploy

### Production Checklist

- [ ] Set strong `SECRET_KEY`
- [ ] Use PostgreSQL (not SQLite)
- [ ] Configure Redis for production
- [ ] Set up proper SSL/TLS
- [ ] Configure CORS appropriately
- [ ] Enable logging and monitoring
- [ ] Set up database backups
- [ ] Configure rate limiting
- [ ] Set appropriate `ACCESS_TOKEN_EXPIRE_MINUTES`
- [ ] Secure API keys and credentials
- [ ] Configure email service properly
- [ ] Test WhatsApp integration (if using)

---

## 💻 Development

### Backend Development

#### Project Structure

The backend follows a **clean architecture** pattern:

```
app/
├── main.py              # Application entry point, router registration
├── database.py          # Database connection and session management
├── oauth2.py            # JWT authentication utilities
├── core/
│   └── config.py        # Configuration and settings
├── models/              # Database models (SQLAlchemy ORM)
│   ├── user.py
│   ├── transactions.py
│   ├── behaviour.py
│   └── goal.py
├── schemas/             # Request/response schemas (Pydantic)
├── routers/             # API endpoints
│   ├── user_router.py
│   ├── transactions_router.py
│   └── ...
├── services/            # Business logic
│   ├── behavior_engine.py
│   ├── email_parser.py
│   └── ...
└── utils/               # Utility functions
```

#### Key Patterns

1. **Dependency Injection**
   - Database sessions via FastAPI dependencies
   - Authentication via `oauth2.get_current_user`

2. **Request/Response Flow**
   ```
   Client → Router → Service → Model → Database
                                  ↓
   Client ← Schema ← Service ← ORM Object
   ```

3. **Error Handling**
   - HTTP exceptions for API errors
   - Structured error responses
   - Validation errors via Pydantic

#### Adding New Features

1. **Create Model** (if database table needed)
   ```python
   # app/models/new_feature.py
   from sqlalchemy import Column, Integer, String
   from app.database import Base
   
   class NewFeature(Base):
       __tablename__ = "new_features"
       id = Column(Integer, primary_key=True)
       name = Column(String)
   ```

2. **Create Schema**
   ```python
   # app/schemas/new_feature.py
   from pydantic import BaseModel
   
   class NewFeatureCreate(BaseModel):
       name: str
   
   class NewFeatureResponse(BaseModel):
       id: int
       name: str
   ```

3. **Create Router**
   ```python
   # app/routers/new_feature_router.py
   from fastapi import APIRouter, Depends
   from sqlalchemy.orm import Session
   from app.database import get_db
   
   router = APIRouter(prefix="/new-feature", tags=["New Feature"])
   
   @router.post("/")
   def create_feature(data: NewFeatureCreate, db: Session = Depends(get_db)):
       # Implementation
       pass
   ```

4. **Register Router**
   ```python
   # app/main.py
   from app.routers import new_feature_router
   app.include_router(new_feature_router.router)
   ```

5. **Create Migration**
   ```bash
   alembic revision --autogenerate -m "Add new feature table"
   alembic upgrade head
   ```

### Mobile Development

#### Architecture

The mobile app uses **BLoC (Business Logic Component)** pattern:

```
lib/
├── core/
│   ├── error/          # Error handling
│   ├── network/        # API client
│   └── usecases/       # Base use case classes
├── features/
│   └── feature_name/
│       ├── data/
│       │   ├── datasources/    # Remote & local data
│       │   ├── models/         # Data models
│       │   └── repositories/   # Repository implementations
│       ├── domain/
│       │   ├── entities/       # Business entities
│       │   ├── repositories/   # Repository interfaces
│       │   └── usecases/       # Business logic
│       └── presentation/
│           ├── bloc/           # State management
│           ├── pages/          # UI screens
│           └── widgets/        # Reusable components
```

#### Adding New Features

1. **Create Entity** (domain/entities)
2. **Create Repository Interface** (domain/repositories)
3. **Create Use Case** (domain/usecases)
4. **Implement Data Layer** (data/)
5. **Create BLoC** (presentation/bloc)
6. **Build UI** (presentation/pages & widgets)
7. **Register Dependencies** (init_dependencies.dart)

### Code Style

#### Backend (Python)
- Follow PEP 8
- Use type hints
- Document with docstrings
- Maximum line length: 100 characters

#### Mobile (Dart/Flutter)
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter analyze` for linting
- Format with `flutter format`

### Environment Variables

Create a `.env` file in the server directory:

```env
# Application
APP_NAME=Kronyx

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/volt_db

# Security
SECRET_KEY=your-super-secret-key-min-32-chars
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0
REDIS_QUEUE_NAME=bank-txn-jobs

# AI
GEMINI_API_KEY=your-gemini-api-key

# Email (optional)
IMAP_HOST=imap.gmail.com
IMAP_PORT=993
IMAP_USERNAME=your-email@gmail.com
IMAP_PASSWORD=your-app-specific-password
IMAP_POLL_INTERVAL=300

# Twilio (optional)
TWILIO_ACCOUNT_SID=your-account-sid
TWILIO_AUTH_TOKEN=your-auth-token
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
TWILIO_CONTENT_SID=your-content-sid

# Worker
DEFAULT_USER_ID=1
```

---

## 🧪 Testing

### Backend Tests

#### Run All Tests
```bash
cd server
pytest
```

#### Run Specific Test File
```bash
pytest tests/test_transactions.py
```

#### Run with Coverage
```bash
pytest --cov=app --cov-report=html
```

#### Test Structure
```
tests/
├── conftest.py              # Pytest configuration & fixtures
├── test_user_router.py      # User authentication tests
├── test_transactions.py     # Transaction CRUD tests
├── test_behavior_engine.py  # Behavior analysis tests
├── test_insights.py         # Insights generation tests
└── test_email_parser.py     # Email parsing tests
```

#### Writing Tests

```python
# tests/test_example.py
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_create_transaction(test_user_token):
    response = client.post(
        "/transactions/",
        headers={"Authorization": f"Bearer {test_user_token}"},
        json={
            "amount": 100.00,
            "description": "Test transaction",
            "category": "GROCERIES"
        }
    )
    assert response.status_code == 201
    assert response.json()["amount"] == 100.00
```

### Mobile Tests

#### Run All Tests
```bash
cd mobile
flutter test
```

#### Run Specific Test
```bash
flutter test test/features/auth/auth_bloc_test.dart
```

#### Run with Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

#### Test Types

1. **Unit Tests**: Test individual functions/classes
2. **Widget Tests**: Test UI components
3. **Integration Tests**: Test feature workflows

```dart
// test/features/auth/auth_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';

void main() {
  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when login succeeds',
      build: () => AuthBloc(mockAuthRepository),
      act: (bloc) => bloc.add(LoginRequested(email: 'test@test.com', password: 'password')),
      expect: () => [
        AuthLoading(),
        AuthSuccess(user: mockUser),
      ],
    );
  });
}
```

### Test Documentation

See [server/docs/TEST_SUITE_SUMMARY.md](server/docs/TEST_SUITE_SUMMARY.md) for comprehensive test documentation.

---

## 📖 Additional Documentation

### Architecture & Design
- [Architecture Diagram](server/docs/ARCHITECTURE_DIAGRAM.md) - System architecture overview
- [Backend Documentation](server/docs/BACKEND.md) - Backend implementation details
- [Freelancer Enhancements](server/docs/FREELANCER_ENHANCEMENTS.md) - Gig worker features

### Features
- [Insights System](server/docs/INSIGHTS.md) - AI insights implementation
- [Gamification](server/docs/GAMIFICATION.md) - Gamification system details
- [Lean Week Predictor](server/docs/LEAN_WEEK_PREDICTOR_README.md) - AI prediction system
- [Quick Reference](server/docs/LEAN_WEEK_QUICK_REFERENCE.md) - Feature quick reference

### Integration Guides
- [Email Parsing](server/docs/USER_EMAIL_PARSING_GUIDE.md) - Email integration setup
- [WhatsApp Integration](server/WHATSAPP_INTEGRATION.md) - WhatsApp setup guide
- [Heroku Deployment](HEROKU_DEPLOYMENT.md) - Cloud deployment guide

### Technical
- [Welford's Algorithm](WELFORD.md) - Variance computation algorithm
- [Implementation Summary](server/docs/IMPLEMENTATION_SUMMARY.md) - Feature implementation status

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Getting Started

1. **Fork the repository**
2. **Clone your fork**
   ```bash
   git clone https://github.com/your-username/Volt.git
   cd Volt
   ```
3. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Make your changes**
5. **Write/update tests**
6. **Run tests and linting**
   ```bash
   # Backend
   cd server
   pytest
   
   # Mobile
   cd mobile
   flutter test
   flutter analyze
   ```
7. **Commit your changes**
   ```bash
   git commit -m "Add: brief description of your changes"
   ```
8. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```
9. **Create a Pull Request**

### Contribution Guidelines

- **Code Style**: Follow the existing code style and conventions
- **Testing**: Add tests for new features
- **Documentation**: Update documentation for significant changes
- **Commits**: Write clear, concise commit messages
- **Pull Requests**: Provide detailed description of changes

### Areas for Contribution

- 🐛 Bug fixes
- ✨ New features
- 📝 Documentation improvements
- 🎨 UI/UX enhancements
- 🧪 Additional test coverage
- 🌐 Internationalization (i18n)
- ♿ Accessibility improvements

### Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the code, not the person
- Help others learn and grow

---

## 🐛 Troubleshooting

### Common Issues

#### Backend Issues

**Problem**: Database connection errors
```bash
sqlalchemy.exc.OperationalError: could not connect to server
```
**Solution**: 
- Ensure PostgreSQL is running
- Check `DATABASE_URL` in `.env`
- Verify database exists: `createdb volt_db`

**Problem**: Redis connection errors
```bash
redis.exceptions.ConnectionError: Error connecting to Redis
```
**Solution**:
- Start Redis: `redis-server` or `docker-compose up redis`
- Check `REDIS_HOST` and `REDIS_PORT` in `.env`

**Problem**: Migration errors
```bash
alembic.util.exc.CommandError: Can't locate revision
```
**Solution**:
- Delete `migrations/versions/` files (backup first!)
- Run `alembic revision --autogenerate -m "Initial migration"`
- Run `alembic upgrade head`

#### Mobile Issues

**Problem**: Dependency conflicts
```bash
Because your_package depends on conflicting versions...
```
**Solution**:
```bash
flutter pub upgrade
flutter pub get
```

**Problem**: Build errors on iOS
```bash
CocoaPods not installed
```
**Solution**:
```bash
sudo gem install cocoapods
cd ios && pod install
```

**Problem**: API connection fails
```bash
SocketException: Failed host lookup
```
**Solution**:
- For Android emulator, use `http://10.0.2.2:8000` instead of `localhost:8000`
- For iOS simulator, `localhost:8000` should work
- For physical devices, use your computer's IP address

### Getting Help

- 📖 Check the [documentation](server/docs/)
- 🐛 Search [existing issues](https://github.com/Vaibhav2154/Volt/issues)
- 💬 Open a [new issue](https://github.com/Vaibhav2154/Volt/issues/new) with details:
  - Operating system
  - Python/Flutter version
  - Error messages
  - Steps to reproduce

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2025 Vaibhav M N

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## 🙏 Acknowledgments

- **FastAPI** - Modern Python web framework
- **Flutter** - Cross-platform mobile framework
- **Google Gemini** - AI-powered insights
- **Pydantic AI** - Structured AI data analysis
- **Twilio** - WhatsApp messaging integration
- **Heroku** - Cloud platform for deployment
- **PostgreSQL** - Robust database system
- **Redis** - High-performance data store

---

## 📞 Support & Contact

- **Repository**: [https://github.com/Vaibhav2154/Volt](https://github.com/Vaibhav2154/Volt)
- **Issues**: [GitHub Issues](https://github.com/Vaibhav2154/Volt/issues)
- **Author**: Vaibhav M N

---

<div align="center">

**Made with ❤️ for freelancers and gig workers**

⭐ Star this repository if you find it useful!

</div>
