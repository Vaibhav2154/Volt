from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy.orm.attributes import flag_modified
from app.models.behaviour import BehaviourModel
from app.services.statistics import StatisticsService
from app.services.categorization import CategorizationService
from app.utils.constants import DECAY_FACTOR

class BehaviorEngine:
    """
    Core engine for incremental learning from transactions.
    Uses PydanticAI for intelligent categorization.
    """
    
    def __init__(self, categorization_service: CategorizationService):
        self.stats_service = StatisticsService()
        self.categorization_service = categorization_service
    
    async def update_model(self, db: Session, user_id: int, transaction) -> BehaviourModel:
        """
        Updates user's behavior model after each transaction.
        
        Steps:
        1. Get or create behavior model
        2. Categorize transaction using hybrid approach (rule-based + LLM)
        3. Apply time decay to existing stats
        4. Update statistics (Welford's algorithm)
        5. Recalculate elasticity
        6. Update baselines
        7. Calculate impulse score
        8. Track temporal patterns
        """
        # Get or create model
        model = db.query(BehaviourModel).filter_by(user_id=user_id).first()
        
        if not model:
            model = BehaviourModel(
                user_id=user_id,
                category_stats={},
                elasticity={},
                baselines={},
                impulse_score=0.0,
                habits={},
                monthly_patterns={}
            )
            db.add(model)
            db.commit()
            db.refresh(model)
        
        # Only process debit transactions
        if transaction.type != "debit":
            return model
        
        # Categorize if not already done (uses hybrid approach)
        if not transaction.category:
            category, confidence = await self.categorization_service.categorize(
                transaction.merchant or "",
                float(transaction.amount),
                transaction.rawMessage or "",
                transaction.type
            )
            transaction.category = category
            # Note: Caller is responsible for committing the transaction
        
        category = transaction.category
        amount = float(transaction.amount)
        
        # Initialize dicts
        stats = model.category_stats or {}
        elasticity = model.elasticity or {}
        baselines = model.baselines or {}
        
        # Apply time decay to existing stats
        if category in stats:
            stats[category] = self.stats_service.apply_time_decay(
                stats[category], 
                DECAY_FACTOR
            )
        
        # Update statistics
        if category not in stats:
            stats[category] = {
                "count": 0, "sum": 0.0, "mean": 0.0,
                "variance": 0.0, "std_dev": 0.0, "m2": 0.0,
                "min": amount, "max": amount
            }
        
        stats[category] = self.stats_service.update_welford_stats(
            stats[category], 
            amount
        )
        
        # Update elasticity
        elasticity[category] = self.stats_service.calculate_elasticity(
            category, 
            stats[category]
        )
        
        # Update baseline
        mean = stats[category]["mean"]
        std_dev = stats[category]["std_dev"]
        baseline = max(0, mean - 1.5 * std_dev)
        
        if category not in baselines:
            baselines[category] = baseline
        else:
            baselines[category] = min(baselines[category], baseline)
        
        # Update impulse score
        impulse_flag = self.stats_service.detect_impulse(transaction, stats)
        model.impulse_score = 0.9 * model.impulse_score + 0.1 * impulse_flag
        
        # Track temporal patterns
        if transaction.timestamp:
            habits = model.habits or {}
            hour = transaction.timestamp.hour
            day_of_week = transaction.timestamp.weekday()
            
            if "hourly_distribution" not in habits:
                habits["hourly_distribution"] = [0] * 24
            habits["hourly_distribution"][hour] += 1
            
            if "weekly_distribution" not in habits:
                habits["weekly_distribution"] = [0] * 7
            habits["weekly_distribution"][day_of_week] += 1
            
            model.habits = habits
        
        # Save everything
        model.category_stats = stats
        model.elasticity = elasticity
        model.baselines = baselines
        model.transaction_count += 1
        model.last_updated = datetime.utcnow()
        
        # Mark JSON fields as modified so SQLAlchemy detects changes
        flag_modified(model, "category_stats")
        flag_modified(model, "elasticity")
        flag_modified(model, "baselines")
        flag_modified(model, "habits")
        
        # Note: Caller is responsible for committing changes
        return model