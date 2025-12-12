from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Annotated
from app.database import get_db
from app.services.behavior_engine import BehaviorEngine
from app.services.simulation import SimulationService
from app.services.categorization import CategorizationService
from app.services.insight_formatter_v2 import InsightFormatter
from app.schemas.simulation_schemas import (
    BehaviourModelResponse, SimulationRequest, SimulationResponse,
    ScenarioComparisonRequest, ScenarioComparisonResponse,
    ReallocationRequest, ReallocationResponse,
    ProjectionRequest, ProjectionResponse
)
from app.schemas.insights import (
    DashboardInsightResponse, ScenarioSummary, ScenarioInsight,
    ComparisonInsightResponse, BehaviorSummaryResponse
)
from app.schemas.transaction_schemas import (
    TransactionCreate, TransactionResponse
)
from app.models.transactions import Transaction
from app.models.user import User
from app.oauth2 import get_current_user
from datetime import datetime, timedelta
import statistics
import os

router = APIRouter(tags=["Simulation & Behavior"])

# Initialize services
categorization_service = CategorizationService(
    gemini_api_key=os.getenv("GEMINI_API_KEY")
)
behavior_engine = BehaviorEngine(categorization_service)
simulation_service = SimulationService()
insight_formatter = InsightFormatter()


# Helper functions
def verify_user_access(user_id: int, current_user: User):
    """Verify user can access their own resources."""
    if user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access another user's data"
        )


def get_user_behavior_model(db: Session, user_id: int):
    """Get behavior model for user or raise 404."""
    from app.models.behaviour import BehaviourModel
    
    model = db.query(BehaviourModel).filter_by(user_id=user_id).first()
    if not model:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No behavior model found for user {user_id}"
        )
    return model


def _get_volatility_level(volatility: float) -> str:
    """Categorize income volatility level."""
    if volatility > 0.4:
        return "HIGH"
    elif volatility > 0.3:
        return "MODERATE"
    else:
        return "STABLE"


def _calculate_emergency_fund(income_stats: dict) -> dict:
    """Calculate recommended emergency fund based on income volatility."""
    avg_income = income_stats.get('mean', 0)
    volatility = income_stats.get('volatility_coefficient', 0)
    
    if volatility > 0.4:
        months = 6
        reason = "high income volatility"
    elif volatility > 0.3:
        months = 3
        reason = "moderate income variability"
    else:
        months = 3
        reason = "standard safety net"
    
    return {
        'months': months,
        'amount': avg_income * months,
        'reason': reason
    }


def _build_income_analysis(income_stats: dict) -> dict:
    """Build comprehensive income analysis for frontend."""
    return {
        'average_monthly': income_stats.get('mean', 0),
        'volatility': income_stats.get('volatility_coefficient', 0),
        'volatility_level': _get_volatility_level(income_stats.get('volatility_coefficient', 0)),
        'income_range': {
            'min': income_stats.get('min', 0),
            'max': income_stats.get('max', 0)
        },
        'payment_frequency': income_stats.get('payment_frequency', {}),
        'recommended_emergency_fund': _calculate_emergency_fund(income_stats),
        'is_gig_worker': income_stats.get('volatility_coefficient', 0) > 0.3
    }


def get_income_stats(db: Session, user_id: int) -> dict | None:
    """
    Calculate income statistics from behavior model.
    
    Returns income volatility, averages, and patterns for the last 6 months.
    """
    from app.models.behaviour import BehaviourModel
    
    model = db.query(BehaviourModel).filter_by(user_id=user_id).first()
    
    if not model or not model.monthly_patterns:
        return None
    
    income_stats = model.monthly_patterns.get('income_stats')
    
    # If income_stats exists and has meaningful data, return it
    if income_stats and income_stats.get('transaction_count', 0) > 0:
        return income_stats
    
    return None


@router.get(
    "/users/{user_id}/insights/dashboard",
    response_model=DashboardInsightResponse,
    summary="Get dashboard insights",
    description="Get personalized dashboard with quick wins, warnings, and behavior summary"
)
async def get_dashboard_insights(
    user_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """
    Get complete dashboard insights for frontend display.
    
    Returns:
    - **Behavior summary**: Top categories, spending patterns, data quality
    - **Quick wins**: Top 3-5 easy opportunities to save money
    - **Risk warnings**: Income volatility, impulse spending, data quality alerts
    - **Recommended actions**: Prioritized next steps
    
    Perfect for the main dashboard screen in your Flutter app.
    """
    verify_user_access(user_id, current_user)
    model = get_user_behavior_model(db, user_id)
    income_stats = get_income_stats(db, user_id)
    
    # Format insights
    behavior_summary = insight_formatter.format_behavior_summary(model, income_stats)
    quick_wins = insight_formatter.get_quick_wins(model)
    risk_warnings = insight_formatter.get_risk_warnings(model, income_stats)
    
    # Generate recommended actions
    recommended_actions = []
    if quick_wins:
        top_win = quick_wins[0]
        recommended_actions.append(
            f"Start with {top_win['category']}: {top_win['action']} to save ${top_win['monthly_savings']:.0f}/month"
        )
    
    if any(w['severity'] == 'high' for w in risk_warnings):
        recommended_actions.append("Review high-priority warnings before making changes")
    
    if model.transaction_count < 50:
        recommended_actions.append("Continue tracking transactions for better personalization")
    
    if not recommended_actions:
        recommended_actions.append("Explore scenario comparisons to find savings opportunities")
    
    # Prepare response with income analysis if available
    response = {
        'behavior_summary': behavior_summary,
        'quick_wins': quick_wins,
        'risk_warnings': risk_warnings,
        'recommended_actions': recommended_actions
    }
    
    # Add income context to response if available
    if income_stats:
        response['income_analysis'] = _build_income_analysis(income_stats)
    
    return response


@router.get(
    "/users/{user_id}/insights/behavior-summary",
    response_model=BehaviorSummaryResponse,
    summary="Get behavior summary",
    description="Get detailed behavior summary with spending patterns and flexibility analysis"
)
async def get_behavior_summary(
    user_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """Get detailed behavior summary for the user."""
    verify_user_access(user_id, current_user)
    model = get_user_behavior_model(db, user_id)
    income_stats = get_income_stats(db, user_id)
    
    return insight_formatter.format_behavior_summary(model, income_stats)



@router.get(
    "/users/{user_id}/behavior",
    response_model=BehaviourModelResponse,
    summary="Get user behavior model",
    description="Retrieves the current behavior model for a user"
)
async def get_behavior_model(
    user_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """Get the behavior model for a specific user"""
    verify_user_access(user_id, current_user)
    return get_user_behavior_model(db, user_id)


@router.post(
    "/users/{user_id}/simulate",
    response_model=SimulationResponse,
    summary="Simulate spending scenarios",
    description="Run what-if simulations for spending reduction or increase, with optional category targeting"
)
async def simulate_spending(
    user_id: int,
    request: SimulationRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """
    Simulate spending scenarios (reduction or increase) with category targeting.
    
    Supports:
    - **Reduction scenarios**: See if you can reduce spending by X%
    - **Increase scenarios**: Understand impact of spending more
    - **Category targeting**: Focus on specific categories only
    
    Returns:
    - Achievable percentage change
    - Category-by-category breakdown with difficulty ratings
    - Actionable recommendations
    - Feasibility assessment
    - Projected monthly and annual impact
    """
    verify_user_access(user_id, current_user)
    
    try:
        result = simulation_service.simulate_spending_scenario(
            db=db,
            user_id=user_id,
            scenario_type=request.scenario_type,
            target_percent=request.target_percent,
            time_period_days=request.time_period_days,
            target_categories=request.target_categories
        )
        return result
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Simulation failed: {str(e)}"
        )


@router.post(
    "/users/{user_id}/simulate/enhanced",
    response_model=ScenarioInsight,
    summary="Simulate spending with enhanced insights",
    description="Run simulation with frontend-ready insights including quick wins, warnings, and timelines"
)
async def simulate_spending_enhanced(
    user_id: int,
    request: SimulationRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """
    Enhanced simulation endpoint with frontend-ready insights.
    
    Returns:
    - Plain-English headline summary
    - Confidence level with reasoning
    - Top 3 quick win opportunities
    - Risk warnings (income volatility, emergency fund, etc.)
    - Timeline estimation
    - Annual impact projection
    
    Perfect for displaying actionable insights in your Flutter app.
    """
    verify_user_access(user_id, current_user)
    
    try:
        # Run simulation
        simulation_result = simulation_service.simulate_spending_scenario(
            db=db,
            user_id=user_id,
            scenario_type=request.scenario_type,
            target_percent=request.target_percent,
            time_period_days=request.time_period_days,
            target_categories=request.target_categories
        )
        
        # Get user model and income stats for context
        model = get_user_behavior_model(db, user_id)
        income_stats = get_income_stats(db, user_id)
        
        # Format for frontend
        # Convert Pydantic model to dict recursively (handles nested models)
        # Use model_dump() for Pydantic v2 which recursively converts nested models
        if hasattr(simulation_result, 'model_dump'):
            simulation_dict = simulation_result.model_dump(mode='python')
        elif hasattr(simulation_result, 'dict'):
            # Pydantic v1 - dict() also recursively converts nested models
            simulation_dict = simulation_result.dict()
        else:
            # Fallback - manually convert
            simulation_dict = dict(simulation_result)
            # Convert nested CategoryAnalysis models to dicts
            if 'category_breakdown' in simulation_dict:
                category_breakdown = simulation_dict['category_breakdown']
                if isinstance(category_breakdown, dict):
                    simulation_dict['category_breakdown'] = {
                        k: v.model_dump(mode='python') if hasattr(v, 'model_dump') 
                        else (v.dict() if hasattr(v, 'dict') else v)
                        for k, v in category_breakdown.items()
                    }
        
        enhanced_result = insight_formatter.format_scenario_summary(
            simulation_dict,
            model,
            income_stats
        )
        
        return enhanced_result
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Simulation failed: {str(e)}"
        )



@router.post(
    "/users/{user_id}/simulate/compare",
    response_model=ScenarioComparisonResponse,
    summary="Compare multiple spending scenarios",
    description="Generate and compare 2-5 different spending scenarios to help choose the best path"
)
async def compare_scenarios(
    user_id: int,
    request: ScenarioComparisonRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """
    Generate and compare multiple spending scenarios.
    
    Provides:
    - Multiple pre-configured scenarios (conservative, moderate, aggressive)
    - Side-by-side comparison of impact and feasibility
    - Recommended scenario based on your profile
    - Visual comparison data for charts
    - Key insights to help decision-making
    """
    verify_user_access(user_id, current_user)
    
    try:
        result = simulation_service.compare_scenarios(
            db=db,
            user_id=user_id,
            scenario_type=request.scenario_type,
            time_period_days=request.time_period_days,
            num_scenarios=request.num_scenarios
        )
        return result
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Scenario comparison failed: {str(e)}"
        )


@router.post(
    "/users/{user_id}/simulate/compare/enhanced",
    response_model=ComparisonInsightResponse,
    summary="Compare scenarios with enhanced insights",
    description="Get frontend-ready comparison insights with trade-off analysis and recommendations"
)
async def compare_scenarios_enhanced(
    user_id: int,
    request: ScenarioComparisonRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """
    Enhanced scenario comparison with frontend-ready insights.
    
    Returns:
    - Recommended scenario highlight
    - Easy vs impactful trade-off analysis
    - Difficulty breakdown across all scenarios
    - Plain-English summaries for decision-making
    
    Perfect for helping users choose between multiple options in your Flutter app.
    """
    verify_user_access(user_id, current_user)
    
    try:
        # Run comparison
        comparison_result = simulation_service.compare_scenarios(
            db=db,
            user_id=user_id,
            scenario_type=request.scenario_type,
            time_period_days=request.time_period_days,
            num_scenarios=request.num_scenarios
        )
        
        # Format for frontend
        # Convert Pydantic model to dict recursively
        if hasattr(comparison_result, 'model_dump'):
            comparison_dict = comparison_result.model_dump(mode='python')
        elif hasattr(comparison_result, 'dict'):
            comparison_dict = comparison_result.dict()
        else:
            comparison_dict = dict(comparison_result)
        
        enhanced_insights = insight_formatter.format_comparison_insights(
            comparison_dict
        )
        
        return {'insights': enhanced_insights}
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Scenario comparison failed: {str(e)}"
        )



@router.post(
    "/users/{user_id}/simulate/reallocate",
    response_model=ReallocationResponse,
    summary="Simulate budget reallocation",
    description="Move money between spending categories while maintaining the same total budget"
)
async def simulate_reallocation(
    user_id: int,
    request: ReallocationRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """
    Simulate budget reallocation between categories.
    
    Example: Move $500 from DINING to SAVINGS and $200 from ENTERTAINMENT to HEALTHCARE.
    
    Rules:
    - Total changes must sum to zero (balanced budget)
    - Provides feasibility analysis for each reallocation
    - Warns about difficult or unrealistic changes
    - Recommends adjustments for better success
    """
    verify_user_access(user_id, current_user)
    
    try:
        result = simulation_service.simulate_reallocation(
            db=db,
            user_id=user_id,
            reallocations=request.reallocations,
            time_period_days=request.time_period_days
        )
        return result
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Reallocation simulation failed: {str(e)}"
        )


@router.post(
    "/users/{user_id}/simulate/project",
    response_model=ProjectionResponse,
    summary="Project future spending",
    description="Forecast spending over multiple months with optional behavioral changes"
)
async def project_future_spending(
    user_id: int,
    request: ProjectionRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """
    Project future spending over 1-24 months.
    
    Features:
    - Month-by-month spending projections
    - Apply behavioral changes (e.g., "reduce DINING by 15%")
    - Cumulative impact tracking
    - Confidence levels (decreases over time)
    - Visual data for trend charts
    
    Perfect for:
    - "What if I maintain this reduction for 6 months?"
    - "How much will I save this year if I cut dining by 20%?"
    - Long-term financial planning
    """
    verify_user_access(user_id, current_user)
    
    try:
        result = simulation_service.project_future_spending(
            db=db,
            user_id=user_id,
            projection_months=request.projection_months,
            time_period_days=request.time_period_days,
            behavioral_changes=request.behavioral_changes,
            scenario_id=request.scenario_id
        )
        return result
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Projection failed: {str(e)}"
        )


@router.post(
    "/transactions/{transaction_id}/recategorize",
    response_model=TransactionResponse,
    summary="Recategorize a transaction",
    description="Force recategorization of a transaction using LLM"
)
async def recategorize_transaction(
    transaction_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Session = Depends(get_db)
):
    """Force recategorization of a specific transaction"""
    tx = db.query(Transaction).filter(
        Transaction.id == transaction_id,
        Transaction.user_id == current_user.id
    ).first()
    
    if not tx:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Transaction {transaction_id} not found"
        )
    
    try:
        # Force LLM categorization
        result = await categorization_service.categorize_with_llm(
            tx.merchant or "",
            float(tx.amount),
            tx.rawMessage or "",
            tx.type
        )
        
        tx.category = result.category
        db.commit()
        db.refresh(tx)
        
        # Update behavior model
        await behavior_engine.update_model(db, tx.user_id, tx)
        
        return tx
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Recategorization failed: {str(e)}"
        )