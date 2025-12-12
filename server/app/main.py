from fastapi import FastAPI
from app.database import engine, Base
from app.routers import user_router, transactions_router, email_transactions, email_config_router, ocr_router
from app.api import simulation_routes
from app.core.config import settings

from app.models.user import User
from app.models.transactions import Transaction
from app.models.behaviour import BehaviourModel

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.app_name,
    description="Kronyx API with Authentication and Email Transaction Processing",
    version="1.0.0"
)

# Include routers
app.include_router(user_router.router)
app.include_router(transactions_router.router)
app.include_router(ocr_router.router)
app.include_router(email_transactions.router)
app.include_router(email_config_router.router)
app.include_router(simulation_routes.router, prefix="/api")

@app.get("/")
def root():
    return {"message": "API is running", "app": settings.app_name}

