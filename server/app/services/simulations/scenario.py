"""
Core scenario simulation logic.
Handles single spending scenarios (reduction/increase).
"""

from datetime import datetime, timedelta
from typing import Dict, List, Optional
from decimal import Decimal
from sqlalchemy.orm import Session

from app.models.transactions import Transaction
from app.models.behaviour import BehaviourModel
from app.utils.constants import DISCRETIONARY_CATEGORIES, ESSENTIAL_CATEGORIES
from app.schemas.simulation_schemas import SimulationResponse, CategoryAnalysis
from .helpers import generate_recommendations


def simulate_spending_scenario(
    db: Session,
    user_id: int,
    scenario_type: str,
    target_percent: float,
    time_period_days: int = 30,
    target_categories: Optional[List[str]] = None
) -> SimulationResponse:
    """
    Simulate spending scenarios (reduction or increase) with optional category targeting.
    
    Args:
        db: Database session
        user_id: User ID to simulate for
        scenario_type: 'reduction' or 'increase'
        target_percent: Target percentage change (1-100)
        time_period_days: Historical period to analyze (default 30 days)
        target_categories: Specific categories to target (None = all categories)
        
    Returns:
        SimulationResponse with detailed analysis and recommendations
        
    Raises:
        ValueError: If no behavior model found or no transactions in period
    """
    
    model = db.query(BehaviourModel).filter_by(user_id=user_id).first()
    if not model:
        raise ValueError("No behavior model found for user")
    
    # Get recent transactions
    cutoff_date = datetime.utcnow() - timedelta(days=time_period_days)
    txs = db.query(Transaction).filter(
        Transaction.user_id == user_id,
        Transaction.type == "debit",
        Transaction.timestamp >= cutoff_date
    ).all()
    
    if not txs:
        raise ValueError("No transactions found in the specified period")
    
    baseline_total = sum(float(t.amount) for t in txs)
    
    # Determine which categories to analyze
    stats = model.category_stats or {}
    elasticity_map = model.elasticity or {}
    
    if target_categories:
        # Validate categories exist
        categories_to_analyze = [c for c in target_categories if c in stats]
        if not categories_to_analyze:
            raise ValueError(f"None of the specified categories found in user data: {target_categories}")
    else:
        categories_to_analyze = list(stats.keys())
    
    # Analyze each category
    category_breakdown = {}
    total_achievable_change = 0
    
    for category in categories_to_analyze:
        cat_stats = stats[category]
        mean_spending = cat_stats.get("mean", 0)
        category_elasticity = elasticity_map.get(category, 0.3)
        
        if scenario_type == "reduction":
            # REDUCTION LOGIC
            # Max reduction limited by elasticity
            max_change_pct = category_elasticity * 100
            achievable_change_pct = min(target_percent, max_change_pct)
            
            # Impulse boost for discretionary categories
            if category in DISCRETIONARY_CATEGORIES:
                impulse_boost = model.impulse_score * 15
                achievable_change_pct = min(
                    achievable_change_pct + impulse_boost,
                    max_change_pct
                )
            
            monthly_change = mean_spending * (achievable_change_pct / 100)
            
        else:  # scenario_type == "increase"
            # INCREASE LOGIC
            # Essential categories: harder to increase (less elastic upward)
            # Discretionary categories: easier to increase
            if category in ESSENTIAL_CATEGORIES:
                # Essential spending has natural limits
                max_change_pct = min(50, category_elasticity * 80)  # Capped increase
                achievable_change_pct = min(target_percent, max_change_pct)
            else:
                # Discretionary can increase more freely
                max_change_pct = min(200, category_elasticity * 150)
                achievable_change_pct = min(target_percent, max_change_pct)
            
            monthly_change = mean_spending * (achievable_change_pct / 100)
        
        total_achievable_change += monthly_change
        
        # Confidence calculation
        count = cat_stats.get("count", 0)
        variance = cat_stats.get("variance", 0)
        # Compute confidence from sample count and variance; clamp to [0,1]
        raw_conf = (count / 20) * (1 - variance / (mean_spending ** 2 + 1))
        # Ensure confidence stays within valid bounds for Pydantic
        confidence = max(0.0, min(1.0, raw_conf))
        
        # Difficulty assessment
        if achievable_change_pct >= target_percent * 0.9:
            difficulty = "easy"
        elif achievable_change_pct >= target_percent * 0.6:
            difficulty = "moderate"
        else:
            difficulty = "challenging"
        
        category_breakdown[category] = CategoryAnalysis(
            current_monthly=round(mean_spending, 2),
            max_reduction_pct=round(max_change_pct, 1),
            achievable_reduction_pct=round(achievable_change_pct, 1),
            monthly_savings=round(monthly_change, 2),
            confidence=round(confidence, 2),
            difficulty=difficulty
        )
    
    # Results
    if scenario_type == "reduction":
        projected_total = baseline_total - total_achievable_change
    else:
        projected_total = baseline_total + total_achievable_change
    
    actual_change_pct = (total_achievable_change / baseline_total * 100) if baseline_total > 0 else 0
    
    # Get income stats for freelancer-aware recommendations
    income_stats = None
    if hasattr(model, 'monthly_patterns') and model.monthly_patterns:
        income_stats = model.monthly_patterns.get('income_stats')
    
    # Generate recommendations (now income-aware for freelancers)
    recommendations = generate_recommendations(
        category_breakdown, 
        model.impulse_score, 
        scenario_type,
        target_categories,
        income_stats
    )
    
    # Determine feasibility
    if actual_change_pct >= target_percent * 0.9:
        feasibility = "highly_achievable"
    elif actual_change_pct >= target_percent * 0.7:
        feasibility = "achievable"
    elif actual_change_pct >= target_percent * 0.5:
        feasibility = "challenging"
    else:
        feasibility = "unrealistic"
    
    return SimulationResponse(
        scenario_type=scenario_type,
        target_percent=target_percent,
        achievable_percent=round(actual_change_pct, 1),
        baseline_monthly=round(baseline_total, 2),
        projected_monthly=round(projected_total, 2),
        total_change=round(total_achievable_change, 2),
        annual_impact=round(total_achievable_change * 12, 2),
        feasibility=feasibility,
        category_breakdown=category_breakdown,
        recommendations=recommendations,
        targeted_categories=target_categories
    )
