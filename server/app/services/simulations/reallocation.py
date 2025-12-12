"""
Budget reallocation simulation logic.
Handles moving money between spending categories.
"""

from datetime import datetime, timedelta
from typing import Dict
from decimal import Decimal
from sqlalchemy.orm import Session

from app.models.transactions import Transaction
from app.models.behaviour import BehaviourModel
from app.utils.constants import ESSENTIAL_CATEGORIES, DISCRETIONARY_CATEGORIES
from app.schemas.simulation_schemas import ReallocationResponse, CategoryReallocation


def simulate_reallocation(
    db: Session,
    user_id: int,
    reallocations: Dict[str, float],
    time_period_days: int = 30
):
    """
    Simulate budget reallocation between categories.
    
    Args:
        db: Database session
        user_id: User ID to simulate for
        reallocations: Dict of category changes (must sum to zero)
        time_period_days: Historical period to analyze
        
    Returns:
        ReallocationResponse with feasibility analysis
    """
    
    model = db.query(BehaviourModel).filter_by(user_id=user_id).first()
    if not model:
        raise ValueError("No behavior model found for user")
    
    # Get baseline data
    cutoff_date = datetime.utcnow() - timedelta(days=time_period_days)
    txs = db.query(Transaction).filter(
        Transaction.user_id == user_id,
        Transaction.type == "debit",
        Transaction.timestamp >= cutoff_date
    ).all()
    
    if not txs:
        raise ValueError("No transactions found in the specified period")
    
    baseline_total = sum(float(t.amount) for t in txs)
    stats = model.category_stats or {}
    elasticity_map = model.elasticity or {}
    
    # Validate reallocation is beneficial (non-essential → essential)
    sources = []  # Categories losing money (should be discretionary)
    targets = []  # Categories gaining money (should be essential or savings)
    
    for category, change in reallocations.items():
        if change < 0:
            sources.append(category)
        elif change > 0:
            targets.append(category)
    
    # Validate sources are discretionary
    for category in sources:
        if category in ESSENTIAL_CATEGORIES:
            raise ValueError(
                f"Cannot reduce essential category '{category}'. "
                f"Reallocations should cut discretionary spending, not essentials."
            )
        if category not in stats:
            raise ValueError(f"Category '{category}' not found in your spending history")
    
    # Validate targets are essential or beneficial
    for category in targets:
        if category not in ESSENTIAL_CATEGORIES and category not in ["SAVINGS", "DEBT_PAYMENT", "INVESTMENT"]:
            raise ValueError(
                f"Cannot increase discretionary category '{category}'. "
                f"Reallocations should move money to essentials, savings, or debt payment."
            )
    
    # Validate all categories exist
    for category in reallocations.keys():
        if category not in stats and category not in ["SAVINGS", "DEBT_PAYMENT", "INVESTMENT", "OTHER"]:
            raise ValueError(f"Category '{category}' not found in your spending history")
    
    # Analyze each reallocation
    reallocation_details = []
    warnings = []
    
    for category, change in reallocations.items():
        if category in ["SAVINGS", "OTHER"] and change > 0:
            # Adding to savings/other - always feasible
            reallocation_details.append(CategoryReallocation(
                category=category,
                current_monthly=Decimal("0"),
                change_amount=Decimal(str(change)),
                new_monthly=Decimal(str(change)),
                change_percent=100.0,
                feasibility="comfortable",
                impact_note=f"Allocating ${abs(change):.2f} to {category}"
            ))
            continue
        
        current = stats.get(category, {}).get("mean", 0)
        new_amount = current + change
        change_percent = (change / current * 100) if current > 0 else 0
        
        # Assess feasibility
        category_elasticity = elasticity_map.get(category, 0.3)
        
        if change < 0:  # Reducing spending
            max_reduction_pct = category_elasticity * 100
            reduction_pct = abs(change_percent)
            
            if reduction_pct <= max_reduction_pct * 0.5:
                feasibility = "comfortable"
                impact = "Easily achievable reduction"
            elif reduction_pct <= max_reduction_pct:
                feasibility = "moderate"
                impact = "Achievable with some effort"
            elif reduction_pct <= max_reduction_pct * 1.5:
                feasibility = "difficult"
                impact = "Challenging - requires significant lifestyle changes"
                warnings.append(f"{category}: Reduction of {reduction_pct:.0f}% may be difficult (max comfortable: {max_reduction_pct:.0f}%)")
            else:
                feasibility = "unrealistic"
                impact = "Likely unrealistic given your spending patterns"
                warnings.append(f"{category}: Reduction of {reduction_pct:.0f}% exceeds recommended maximum")
        
        else:  # Increasing spending
            if category in ESSENTIAL_CATEGORIES:
                if change_percent <= 20:
                    feasibility = "comfortable"
                    impact = "Reasonable increase for essential category"
                elif change_percent <= 40:
                    feasibility = "moderate"
                    impact = "Noticeable increase - ensure it's necessary"
                else:
                    feasibility = "difficult"
                    impact = "Large increase for essential spending"
                    warnings.append(f"{category}: Increase of {change_percent:.0f}% is substantial for an essential category")
            else:  # Discretionary
                if change_percent <= 50:
                    feasibility = "comfortable"
                    impact = "Comfortable discretionary increase"
                elif change_percent <= 100:
                    feasibility = "moderate"
                    impact = "Significant lifestyle upgrade"
                else:
                    feasibility = "difficult"
                    impact = "Major spending increase"
        
        reallocation_details.append(CategoryReallocation(
            category=category,
            current_monthly=Decimal(str(current)),
            change_amount=Decimal(str(change)),
            new_monthly=Decimal(str(new_amount)),
            change_percent=change_percent,
            feasibility=feasibility,
            impact_note=impact
        ))
    
    # Overall feasibility
    feasibility_scores = {"comfortable": 0, "moderate": 1, "difficult": 2, "unrealistic": 3}
    avg_difficulty = sum(feasibility_scores[r.feasibility] for r in reallocation_details) / len(reallocation_details)
    
    if avg_difficulty <= 0.5:
        overall = "This reallocation is comfortable and achievable"
    elif avg_difficulty <= 1.5:
        overall = "This reallocation is moderately challenging but achievable"
    elif avg_difficulty <= 2.5:
        overall = "This reallocation will be difficult and requires strong commitment"
    else:
        overall = "This reallocation may be unrealistic - consider a more moderate approach"
    
    # Generate recommendations
    recommendations = []
    increases = [r for r in reallocation_details if r.change_amount > 0]
    decreases = [r for r in reallocation_details if r.change_amount < 0]
    
    if increases and decreases:
        recommendations.append(f"You're moving ${sum(abs(float(r.change_amount)) for r in decreases):.2f} from {len(decreases)} categories to {len(increases)} categories")
    
    difficult_ones = [r for r in reallocation_details if r.feasibility in ["difficult", "unrealistic"]]
    if difficult_ones:
        recommendations.append(f"Consider adjusting {', '.join(r.category for r in difficult_ones[:2])} reallocations for better success")
    
    if model.impulse_score > 0.6:
        recommendations.append("Your impulse score suggests focusing on discretionary spending reductions first")
    
    # Visual data
    visual_data = {
        "categories": [r.category for r in reallocation_details],
        "current": [float(r.current_monthly) for r in reallocation_details],
        "changes": [float(r.change_amount) for r in reallocation_details],
        "new": [float(r.new_monthly) for r in reallocation_details],
        "feasibility": [r.feasibility for r in reallocation_details]
    }
    
    return ReallocationResponse(
        baseline_monthly=Decimal(str(baseline_total)),
        projected_monthly=Decimal(str(baseline_total)),  # No net change
        is_balanced=True,
        reallocations=reallocation_details,
        feasibility_assessment=overall,
        warnings=warnings,
        recommendations=recommendations,
        visual_data=visual_data
    )
