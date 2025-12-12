"""
Future spending projection logic.
Handles month-by-month spending forecasts.
"""

from datetime import datetime, timedelta
from typing import Dict, Optional
from decimal import Decimal
from sqlalchemy.orm import Session
from calendar import month_name
import random

from app.models.transactions import Transaction
from app.models.behaviour import BehaviourModel
from app.schemas.simulation_schemas import ProjectionResponse, MonthlyProjection


def project_future_spending(
    db: Session,
    user_id: int,
    projection_months: int,
    time_period_days: int = 30,
    behavioral_changes: Optional[Dict[str, float]] = None,
    scenario_id: Optional[str] = None
):
    """
    Project future spending with optional behavioral changes.
    
    Args:
        db: Database session
        user_id: User ID to simulate for
        projection_months: Number of months to project
        time_period_days: Historical period to analyze
        behavioral_changes: Expected category percentage changes
        scenario_id: Apply a scenario from comparison
        
    Returns:
        ProjectionResponse with month-by-month projections
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
    
    baseline_monthly = sum(float(t.amount) for t in txs)
    stats = model.category_stats or {}
    
    # Determine changes to apply
    changes = behavioral_changes or {}
    
    # Generate monthly projections
    monthly_projections = []
    cumulative_change = 0
    current_date = datetime.utcnow()
    
    for month_num in range(1, projection_months + 1):
        # Calculate month details
        target_month = (current_date.month + month_num - 1) % 12 + 1
        month_label = f"{month_name[target_month]} {current_date.year + (current_date.month + month_num - 1) // 12}"
        
        # Apply changes to each category
        category_spending = {}
        month_total = 0
        
        for category, cat_stats in stats.items():
            base_amount = cat_stats.get("mean", 0)
            
            # Apply behavioral change if specified
            change_pct = changes.get(category, 0)
            adjusted_amount = base_amount * (1 + change_pct / 100)
            
            # Add slight natural variation (±5%) for realism
            random.seed(month_num)  # Consistent "randomness"
            variation = random.uniform(-0.05, 0.05)
            projected_amount = adjusted_amount * (1 + variation)
            
            category_spending[category] = Decimal(str(round(projected_amount, 2)))
            month_total += projected_amount
        
        # Confidence decreases over time
        confidence = max(0.5, 1.0 - (month_num * 0.03))  # 3% decrease per month
        
        month_change = month_total - baseline_monthly
        cumulative_change += month_change
        
        monthly_projections.append(MonthlyProjection(
            month=month_num,
            month_label=month_label,
            projected_spending=Decimal(str(round(month_total, 2))),
            category_breakdown=category_spending,
            cumulative_change=Decimal(str(round(cumulative_change, 2))),
            confidence=confidence
        ))
    
    # Calculate totals
    total_projected = sum(float(m.projected_spending) for m in monthly_projections)
    total_baseline = baseline_monthly * projection_months
    total_change = total_projected - total_baseline
    annual_impact = (total_change / projection_months) * 12
    
    # Trend analysis
    if len(changes) > 0:
        avg_change = sum(changes.values()) / len(changes)
        if avg_change < -5:
            trend = "Decreasing trend with planned reductions"
        elif avg_change > 5:
            trend = "Increasing trend with planned expansions"
        else:
            trend = "Stable spending with minor adjustments"
    else:
        trend = "Stable baseline projection with natural variations"
    
    # Confidence level
    if projection_months <= 3:
        confidence_level = "High"
    elif projection_months <= 6:
        confidence_level = "Moderate"
    elif projection_months <= 12:
        confidence_level = "Low"
    else:
        confidence_level = "Very Low"
    
    # Key insights
    insights = []
    insights.append(f"Total projected spending over {projection_months} months: ${total_projected:,.2f}")
    
    if total_change != 0:
        change_word = "savings" if total_change < 0 else "increase"
        insights.append(f"Expected {change_word}: ${abs(total_change):,.2f} compared to baseline")
    
    if behavioral_changes:
        most_reduced = min(changes.items(), key=lambda x: x[1]) if changes else None
        most_increased = max(changes.items(), key=lambda x: x[1]) if changes else None
        
        if most_reduced and most_reduced[1] < 0:
            insights.append(f"Largest planned reduction: {most_reduced[0]} ({most_reduced[1]:.0f}%)")
        if most_increased and most_increased[1] > 0:
            insights.append(f"Largest planned increase: {most_increased[0]} ({most_increased[1]:.0f}%)")
    
    insights.append(f"Confidence decreases over time - {confidence_level.lower()} confidence for this time horizon")
    
    # Chart data
    projection_chart = {
        "months": [m.month_label for m in monthly_projections],
        "projected": [float(m.projected_spending) for m in monthly_projections],
        "baseline": [baseline_monthly] * projection_months,
        "cumulative_change": [float(m.cumulative_change) for m in monthly_projections],
        "confidence": [float(m.confidence) for m in monthly_projections]
    }
    
    return ProjectionResponse(
        baseline_monthly=Decimal(str(baseline_monthly)),
        projection_months=projection_months,
        monthly_projections=monthly_projections,
        total_projected=Decimal(str(round(total_projected, 2))),
        total_baseline=Decimal(str(round(total_baseline, 2))),
        cumulative_change=Decimal(str(round(total_change, 2))),
        annual_impact=Decimal(str(round(annual_impact, 2))),
        trend_analysis=trend,
        confidence_level=confidence_level,
        key_insights=insights,
        projection_chart=projection_chart
    )
