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
    
    @staticmethod
    def calculate_income_expense_ratio(income_stats: Dict, expense_stats: Dict) -> Dict:
        """
        Calculate income-to-expense ratio for freelancers/gig workers.
        
        Returns:
            Dict with ratio analysis and sustainability metrics
        """
        income_mean = income_stats.get('mean', 0.0)
        income_std = income_stats.get('std_dev', 0.0)
        income_min = income_stats.get('min', 0.0)
        
        # Calculate total expense mean from all categories
        total_expense_mean = sum(
            cat_stats.get('mean', 0.0) 
            for cat_stats in expense_stats.values()
        )
        
        # Calculate worst-case and best-case scenarios
        worst_case_income = max(0, income_mean - 1.5 * income_std)
        best_case_income = income_mean + 1.5 * income_std
        
        # Income-to-expense ratios
        avg_ratio = income_mean / total_expense_mean if total_expense_mean > 0 else 0.0
        worst_case_ratio = worst_case_income / total_expense_mean if total_expense_mean > 0 else 0.0
        best_case_ratio = best_case_income / total_expense_mean if total_expense_mean > 0 else 0.0
        
        # Sustainability assessment for variable income
        if worst_case_ratio >= 1.2:
            sustainability = "excellent"
            risk_level = "low"
        elif worst_case_ratio >= 1.0:
            sustainability = "good"
            risk_level = "low"
        elif worst_case_ratio >= 0.8:
            sustainability = "moderate"
            risk_level = "medium"
        elif worst_case_ratio >= 0.6:
            sustainability = "challenging"
            risk_level = "high"
        else:
            sustainability = "critical"
            risk_level = "very_high"
        
        # Calculate buffer needed for lean months
        monthly_shortfall = max(0, total_expense_mean - worst_case_income)
        recommended_buffer = monthly_shortfall * 3  # 3 months of worst-case coverage
        
        return {
            'avg_income': round(income_mean, 2),
            'avg_expenses': round(total_expense_mean, 2),
            'avg_ratio': round(avg_ratio, 2),
            'worst_case_ratio': round(worst_case_ratio, 2),
            'best_case_ratio': round(best_case_ratio, 2),
            'sustainability': sustainability,
            'risk_level': risk_level,
            'income_volatility': round(income_std / income_mean if income_mean > 0 else 0, 2),
            'recommended_buffer': round(recommended_buffer, 2),
            'monthly_shortfall_risk': round(monthly_shortfall, 2)
        }
    
    @staticmethod
    def analyze_income_patterns(income_stats: Dict) -> Dict:
        """
        Analyze income patterns for freelancers/gig workers.
        
        Returns:
            Dict with pattern analysis and recommendations
        """
        freq_days = income_stats.get('income_frequency_days', [])
        sources = income_stats.get('sources', {})
        volatility = income_stats.get('volatility_coefficient', 0.0)
        
        # Extract business vs personal income
        business_income = income_stats.get('business_income', {})
        personal_income = income_stats.get('personal_income', {})
        business_ratio = business_income.get('sum', 0) / income_stats.get('sum', 1) if income_stats.get('sum', 0) > 0 else 0
        
        # Analyze payment frequency
        if freq_days:
            avg_gap = sum(freq_days) / len(freq_days)
            max_gap = max(freq_days)
            min_gap = min(freq_days)
        else:
            avg_gap = max_gap = min_gap = 0
        
        # Client diversity (important for risk mitigation)
        num_sources = len(sources)
        if num_sources > 0:
            total_income = sum(s['total'] for s in sources.values())
            # Calculate income concentration (Herfindahl index)
            concentration = sum(
                (s['total'] / total_income) ** 2 
                for s in sources.values()
            ) if total_income > 0 else 1.0
        else:
            concentration = 0.0
        
        # Assess diversity
        if num_sources >= 5 and concentration < 0.3:
            diversity_level = "excellent"
        elif num_sources >= 3 and concentration < 0.5:
            diversity_level = "good"
        elif num_sources >= 2 and concentration < 0.7:
            diversity_level = "moderate"
        else:
            diversity_level = "low"
        
        # Income stability assessment
        if volatility < 0.2:
            stability = "stable"
        elif volatility < 0.4:
            stability = "moderately_variable"
        elif volatility < 0.6:
            stability = "variable"
        else:
            stability = "highly_variable"
        
        return {
            'payment_frequency_days': round(avg_gap, 1),
            'longest_gap_days': max_gap,
            'shortest_gap_days': min_gap,
            'income_sources': num_sources,
            'client_concentration': round(concentration, 2),
            'diversity_level': diversity_level,
            'volatility_coefficient': round(volatility, 2),
            'stability': stability,
            'business_income_ratio': round(business_ratio, 2),
            'business_income_count': business_income.get('count', 0),
            'personal_income_count': personal_income.get('count', 0)
        }