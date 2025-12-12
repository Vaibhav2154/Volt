from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Annotated
from app.database import get_db
from app.services.behavior_engine import BehaviorEngine
from app.services.simulation import SimulationService
from app.services.categorization import CategorizationService
from app.schemas.simulation_schemas import (
    BehaviourModelResponse, SimulationRequest, SimulationResponse,
    ScenarioComparisonRequest, ScenarioComparisonResponse,
    ReallocationRequest, ReallocationResponse,
    ProjectionRequest, ProjectionResponse
)
from app.schemas.transaction_schemas import (
    TransactionCreate, TransactionResponse
)
from app.models.transactions import Transaction
from app.models.user import User
from app.oauth2 import get_current_user
import os

router = APIRouter(tags=["Simulation & Behavior"])

# Initialize services
categorization_service = CategorizationService(
    gemini_api_key=os.getenv("GEMINI_API_KEY")
)
behavior_engine = BehaviorEngine(categorization_service)
simulation_service = SimulationService()



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
    # Verify the user can only access their own behavior model
    if user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access another user's behavior model"
        )
    
    from app.models.behaviour import BehaviourModel
    
    model = db.query(BehaviourModel).filter_by(user_id=user_id).first()
    
    if not model:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No behavior model found for user {user_id}"
        )
    
    return model


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
    # Verify the user can only simulate their own spending
    if user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to simulate another user's spending"
        )
    
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
    # Verify the user can only compare their own scenarios
    if user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to compare scenarios for another user"
        )
    
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
    if user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to simulate reallocation for another user"
        )
    
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
    if user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to project spending for another user"
        )
    
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