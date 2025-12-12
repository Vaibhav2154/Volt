from sqlalchemy import Column, Integer, ForeignKey, JSON, Float, DateTime, func
from sqlalchemy.orm import relationship
from app.database import Base

class BehaviourModel(Base):
    __tablename__ = "behaviour_models"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    
    # Core statistics (stored as JSON for flexibility)
    category_stats = Column(JSON, default={})
    elasticity = Column(JSON, default={})
    baselines = Column(JSON, default={})
    
    # Behavioral scores
    impulse_score = Column(Float, default=0.0)
    
    # Patterns
    habits = Column(JSON, default={})
    monthly_patterns = Column(JSON, default={})
    
    # Metadata
    last_updated = Column(DateTime(timezone=True), server_default=func.now())
    transaction_count = Column(Integer, default=0)
    
    # RELATIONSHIP
    user = relationship("User", back_populates="behaviour_model")