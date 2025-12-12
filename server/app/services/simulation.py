"""
Main simulation service that coordinates all simulation operations.
Acts as the main interface for simulation functionality.
"""

from sqlalchemy.orm import Session
from typing import Dict, List, Optional

from app.services.simulation_scenario import simulate_spending_scenario as _simulate_spending_scenario
from app.services.simulation_comparison import compare_scenarios as _compare_scenarios
from app.services.simulation_reallocation import simulate_reallocation as _simulate_reallocation
from app.services.simulation_projection import project_future_spending as _project_future_spending


class SimulationService:
    """
    Unified service for all simulation operations.
    Delegates to specialized modules for each simulation type.
    """
    
    @staticmethod
    def simulate_spending_scenario(
        db: Session,
        user_id: int,
        scenario_type: str,
        target_percent: float,
        time_period_days: int = 30,
        target_categories: Optional[List[str]] = None
    ):
        """
        Simulate spending scenarios (reduction or increase) with optional category targeting.
        
        See simulation_scenario.py for implementation details.
        """
        return _simulate_spending_scenario(
            db=db,
            user_id=user_id,
            scenario_type=scenario_type,
            target_percent=target_percent,
            time_period_days=time_period_days,
            target_categories=target_categories
        )
    
    @staticmethod
    def compare_scenarios(
        db: Session,
        user_id: int,
        scenario_type: str,
        time_period_days: int = 30,
        num_scenarios: int = 3
    ):
        """
        Generate and compare multiple spending scenarios.
        
        See simulation_comparison.py for implementation details.
        """
        return _compare_scenarios(
            db=db,
            user_id=user_id,
            scenario_type=scenario_type,
            time_period_days=time_period_days,
            num_scenarios=num_scenarios
        )
    
    @staticmethod
    def simulate_reallocation(
        db: Session,
        user_id: int,
        reallocations: Dict[str, float],
        time_period_days: int = 30
    ):
        """
        Simulate budget reallocation between categories.
        
        See simulation_reallocation.py for implementation details.
        """
        return _simulate_reallocation(
            db=db,
            user_id=user_id,
            reallocations=reallocations,
            time_period_days=time_period_days
        )
    
    @staticmethod
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
        
        See simulation_projection.py for implementation details.
        """
        return _project_future_spending(
            db=db,
            user_id=user_id,
            projection_months=projection_months,
            time_period_days=time_period_days,
            behavioral_changes=behavioral_changes,
            scenario_id=scenario_id
        )
