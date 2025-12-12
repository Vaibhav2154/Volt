from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy.orm.attributes import flag_modified
from app.models.behaviour import BehaviourModel
from app.services.statistics import StatisticsService
from app.services.categorization import CategorizationService
from app.utils.constants import DECAY_FACTOR
from app.utils.datetime_utils import utc_now, ensure_utc, safe_isoformat, safe_fromisoformat

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
        9. Track income patterns (for freelancers/gig workers)
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
        
        # Handle income transactions (credit) for freelancers/gig workers
        if transaction.type == "credit":
            return await self._update_income_stats(model, transaction)
        
        # Process expense transactions (debit)
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
        model.last_updated = utc_now()
        
        # Mark JSON fields as modified so SQLAlchemy detects changes
        flag_modified(model, "category_stats")
        flag_modified(model, "elasticity")
        flag_modified(model, "baselines")
        flag_modified(model, "habits")
        
        # Note: Caller is responsible for committing changes
        return model
    
    async def _update_income_stats(self, model: BehaviourModel, transaction) -> BehaviourModel:
        """
        Track income patterns for freelancers/gig workers with variable income.
        
        Tracks:
        - Income frequency and amounts
        - Income volatility (critical for freelancers)
        - Income sources (client diversity)
        - Income-to-expense ratio
        - Business vs personal income (for tax/accounting)
        """
        amount = float(transaction.amount)
        source = transaction.merchant or "Unknown Source"
        
        # Determine if this is business income or personal income
        # Business income indicators: client payments, project work, gig platforms
        business_keywords = ["client", "project", "upwork", "fiverr", "freelance", 
                           "consulting", "contractor", "gig", "invoice", "payment for"]
        personal_keywords = ["gift", "refund", "cashback", "bonus", "salary", 
                           "payroll", "dividend", "interest", "tax refund"]
        
        source_lower = source.lower()
        raw_msg_lower = (transaction.rawMessage or "").lower()
        
        is_business_income = any(keyword in source_lower or keyword in raw_msg_lower 
                                for keyword in business_keywords)
        is_personal_income = any(keyword in source_lower or keyword in raw_msg_lower 
                               for keyword in personal_keywords)
        
        # Default: if freelancer-related terms, assume business; otherwise personal
        income_type = "business" if is_business_income and not is_personal_income else "personal"
        
        # Initialize income stats if not present
        if not hasattr(model, 'monthly_patterns') or model.monthly_patterns is None:
            model.monthly_patterns = {}
        
        # Separate buckets for business and personal income
        income_stats = model.monthly_patterns.get('income_stats', {
            'count': 0,
            'sum': 0.0,
            'mean': 0.0,
            'variance': 0.0,
            'std_dev': 0.0,
            'm2': 0.0,
            'min': amount,
            'max': amount,
            'sources': {},
            'last_income_date': None,
            'income_frequency_days': [],
            'business_income': {
                'count': 0,
                'sum': 0.0,
                'mean': 0.0,
                'sources': {}
            },
            'personal_income': {
                'count': 0,
                'sum': 0.0,
                'mean': 0.0,
                'sources': {}
            }
        })
        
        # Update Welford stats for income, but preserve non-numeric fields
        stat_keys = {"count", "sum", "mean", "variance", "std_dev", "m2", "min", "max"}
        extras = {k: v for k, v in income_stats.items() if k not in stat_keys}
        income_stats = self.stats_service.update_welford_stats(income_stats, amount)
        # Merge extras back (sources, last_income_date, income_frequency_days, etc.)
        income_stats.update(extras)
        
        # Track income sources (client diversity for freelancers)
        sources = income_stats.get('sources', {})
        if source not in sources:
            sources[source] = {'count': 0, 'total': 0.0, 'type': income_type}
        sources[source]['count'] += 1
        sources[source]['total'] += amount
        income_stats['sources'] = sources
        
        # Update business vs personal income buckets
        bucket_key = f'{income_type}_income'
        if bucket_key not in income_stats:
            income_stats[bucket_key] = {'count': 0, 'sum': 0.0, 'mean': 0.0, 'sources': {}}
        
        bucket = income_stats[bucket_key]
        bucket['count'] += 1
        bucket['sum'] += amount
        bucket['mean'] = bucket['sum'] / bucket['count']
        
        # Track sources in bucket
        if source not in bucket.get('sources', {}):
            bucket.setdefault('sources', {})[source] = {'count': 0, 'total': 0.0}
        bucket['sources'][source]['count'] += 1
        bucket['sources'][source]['total'] += amount
        
        # Track income frequency (gaps between payments)
        if transaction.timestamp:
            last_date = income_stats.get('last_income_date')
            if last_date:
                last_date_parsed = safe_fromisoformat(last_date) if isinstance(last_date, str) else ensure_utc(last_date)
                current_timestamp = ensure_utc(transaction.timestamp)
                if last_date_parsed and current_timestamp:
                    days_since_last = (current_timestamp - last_date_parsed).days
                    freq_list = income_stats.get('income_frequency_days', [])
                    freq_list.append(days_since_last)
                    # Keep only last 20 frequency measurements
                    income_stats['income_frequency_days'] = freq_list[-20:]
            
            income_stats['last_income_date'] = safe_isoformat(ensure_utc(transaction.timestamp))
        
        # Calculate income volatility coefficient (critical for freelancers)
        if income_stats['mean'] > 0:
            income_stats['volatility_coefficient'] = income_stats['std_dev'] / income_stats['mean']
        else:
            income_stats['volatility_coefficient'] = 0.0
        
        # Save income stats
        model.monthly_patterns['income_stats'] = income_stats
        model.transaction_count += 1
        model.last_updated = utc_now()
        
        flag_modified(model, "monthly_patterns")
        
        return model