import math
from typing import Dict
from decimal import Decimal

class StatisticsService:
    """Handles all statistical computations using Welford's algorithm"""
    
    @staticmethod
    def update_welford_stats(stats: Dict, new_amount: float) -> Dict:
        """
        Updates mean and variance incrementally using Welford's algorithm.
        
        Why Welford's Algorithm?
        - Numerically stable (no catastrophic cancellation)
        - O(1) space and time per update
        - Can compute variance without storing all values
        - Single pass through data
        """
        n = stats.get("count", 0) + 1
        mean = stats.get("mean", 0.0)
        m2 = stats.get("m2", 0.0)
        
        # Welford's algorithm
        delta = new_amount - mean
        mean += delta / n
        delta2 = new_amount - mean
        m2 += delta * delta2
        
        variance = m2 / n if n > 1 else 0.0
        std_dev = math.sqrt(variance)
        
        return {
            "count": n,
            "sum": stats.get("sum", 0.0) + new_amount,
            "mean": mean,
            "variance": variance,
            "std_dev": std_dev,
            "m2": m2,
            "min": min(stats.get("min", new_amount), new_amount),
            "max": max(stats.get("max", new_amount), new_amount)
        }
    
    @staticmethod
    def apply_time_decay(stats: Dict, decay_factor: float = 0.98) -> Dict:
        """Apply exponential decay to make recent data more relevant"""
        if stats.get("count", 0) == 0:
            return stats
        
        return {
            **stats,
            "mean": stats["mean"] * decay_factor,
            "variance": stats["variance"] * decay_factor,
            "m2": stats["m2"] * decay_factor
        }
    
    @staticmethod
    def calculate_elasticity(category: str, stats: Dict) -> float:
        """
        Calculate spending elasticity (0.0 = inflexible, 1.0 = fully flexible)
        """
        from app.utils.constants import ELASTICITY_CONFIG
        
        mean = stats.get("mean", 0)
        variance = stats.get("variance", 0)
        
        # Base elasticity from config
        base_elasticity = ELASTICITY_CONFIG.get(category, 0.40)
        
        # Volatility bonus (coefficient of variation)
        if mean > 0:
            coefficient_of_variation = math.sqrt(variance) / mean
            volatility_bonus = min(0.25, coefficient_of_variation * 0.5)
        else:
            volatility_bonus = 0
        
        return min(1.0, base_elasticity + volatility_bonus)
    
    @staticmethod
    def detect_impulse(transaction, user_stats: Dict) -> float:
        """
        Calculate impulse score (0.0 to 1.0) for a transaction.
        
        Factors:
        1. Z-score: How unusual is this amount?
        2. Category: Discretionary vs essential
        3. Time: Late night purchases more impulsive
        4. Day: Weekend purchases more impulsive
        """
        from app.utils.constants import DISCRETIONARY_CATEGORIES
        
        amount = float(transaction.amount)
        category = transaction.category or "OTHER"
        
        # Get category baseline
        cat_stats = user_stats.get(category, {"mean": 0, "std_dev": 1})
        mean = cat_stats.get("mean", 0)
        std_dev = cat_stats.get("std_dev", 1)
        
        # Factor 1: Z-score (statistical deviation)
        if mean > 0 and std_dev > 0:
            z_score = abs(amount - mean) / std_dev
            z_factor = min(1.0, z_score / 2.5)
        else:
            z_factor = 0.3
        
        # Factor 2: Category type
        discretionary_mult = 1.5 if category in DISCRETIONARY_CATEGORIES else 1.0
        
        # Factor 3: Time of day
        hour = transaction.timestamp.hour if transaction.timestamp else 12
        time_mult = 1.3 if (hour >= 22 or hour <= 6) else 1.0
        
        # Factor 4: Weekend
        is_weekend = transaction.timestamp.weekday() >= 5 if transaction.timestamp else False
        weekend_mult = 1.2 if is_weekend else 1.0
        
        # Combine all factors
        impulse_score = z_factor * discretionary_mult * time_mult * weekend_mult
        return min(1.0, impulse_score)