"""
Simulation services package.
Contains all simulation-related functionality.
"""

from .comparison import compare_scenarios
from .helpers import (
    generate_reduction_scenarios,
    generate_increase_scenarios,
    calculate_difficulty_score,
    select_recommended_scenario,
    generate_comparison_insights,
    generate_recommendations
)
from .projection import project_future_spending
from .reallocation import simulate_reallocation
from .scenario import simulate_spending_scenario

__all__ = [
    'compare_scenarios',
    'generate_reduction_scenarios',
    'generate_increase_scenarios',
    'calculate_difficulty_score',
    'select_recommended_scenario',
    'generate_comparison_insights',
    'generate_recommendations',
    'project_future_spending',
    'simulate_reallocation',
    'simulate_spending_scenario',
]
