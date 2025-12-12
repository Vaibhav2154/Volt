"""
Multiple scenario comparison logic.
Generates and compares different spending scenarios.
"""

from datetime import datetime, timedelta
from typing import List
from decimal import Decimal
from sqlalchemy.orm import Session

from app.models.transactions import Transaction
from app.models.behaviour import BehaviourModel
from app.schemas.simulation_schemas import ScenarioComparisonResponse, ScenarioSummary
from app.services.simulation_scenario import simulate_spending_scenario
from app.services.simulation_helpers import (
    generate_reduction_scenarios,
    generate_increase_scenarios,
    calculate_difficulty_score,
    select_recommended_scenario,
    generate_comparison_insights
)


def compare_scenarios(
    db: Session,
    user_id: int,
    scenario_type: str,
    time_period_days: int = 30,
    num_scenarios: int = 3
) -> ScenarioComparisonResponse:
    """
    Generate and compare multiple spending scenarios.
    
    Args:
        db: Database session
        user_id: User ID to simulate for
        scenario_type: 'reduction' or 'increase'
        time_period_days: Historical period to analyze
        num_scenarios: Number of scenarios to generate (2-5)
        
    Returns:
        ScenarioComparisonResponse with multiple scenarios and comparison data
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
    
    # Define scenario parameters based on type
    if scenario_type == "reduction":
        scenario_configs = generate_reduction_scenarios(num_scenarios, stats, elasticity_map)
    else:
        scenario_configs = generate_increase_scenarios(num_scenarios, stats, elasticity_map)
    
    # Run simulation for each scenario
    scenarios = []
    for config in scenario_configs:
        result = simulate_spending_scenario(
            db=db,
            user_id=user_id,
            scenario_type=scenario_type,
            target_percent=config["target_percent"],
            time_period_days=time_period_days,
            target_categories=config.get("target_categories")
        )
        
        # Calculate difficulty score
        difficulty_score = calculate_difficulty_score(
            result.category_breakdown,
            result.achievable_percent,
            result.target_percent
        )
        
        # Get top affected categories
        top_categories = sorted(
            result.category_breakdown.items(),
            key=lambda x: float(x[1].monthly_savings),
            reverse=True
        )[:3]
        
        scenarios.append(ScenarioSummary(
            scenario_id=config["id"],
            name=config["name"],
            description=config["description"],
            scenario_type=scenario_type,
            target_percent=result.target_percent,
            achievable_percent=result.achievable_percent,
            baseline_monthly=result.baseline_monthly,
            projected_monthly=result.projected_monthly,
            total_change=result.total_change,
            annual_impact=result.annual_impact,
            feasibility=result.feasibility,
            difficulty_score=difficulty_score,
            top_categories=[cat[0] for cat in top_categories],
            key_insight=config["key_insight"]
        ))
    
    # Determine recommended scenario (balance of achievability and impact)
    recommended = select_recommended_scenario(scenarios, scenario_type)
    
    # Generate comparison chart data
    comparison_chart = {
        "scenarios": [s.scenario_id for s in scenarios],
        "target_percents": [float(s.target_percent) for s in scenarios],
        "achievable_percents": [float(s.achievable_percent) for s in scenarios],
        "monthly_changes": [float(s.total_change) for s in scenarios],
        "annual_impacts": [float(s.annual_impact) for s in scenarios],
        "difficulty_scores": [float(s.difficulty_score) for s in scenarios],
        "feasibility_levels": [s.feasibility for s in scenarios]
    }
    
    # Generate insights
    insights = generate_comparison_insights(scenarios, scenario_type, model.impulse_score)
    
    return ScenarioComparisonResponse(
        scenario_type=scenario_type,
        baseline_monthly=Decimal(str(baseline_total)),
        time_period_days=time_period_days,
        scenarios=scenarios,
        recommended_scenario_id=recommended,
        comparison_chart=comparison_chart,
        insights=insights
    )
