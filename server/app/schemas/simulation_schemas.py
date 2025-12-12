from pydantic import BaseModel, Field, field_validator
from typing import Optional, Literal
from datetime import datetime
from decimal import Decimal

class CategoryStats(BaseModel):
    """Statistics for a spending category"""
    count: int = Field(ge=0)
    sum: Decimal = Field(ge=0)
    mean: Decimal = Field(ge=0)
    variance: Decimal = Field(ge=0)
    std_dev: Decimal = Field(ge=0)
    min: Decimal = Field(ge=0)
    max: Decimal = Field(ge=0)


class BehaviourModelResponse(BaseModel):
    """Response schema for behavior model"""
    id: int
    user_id: int
    category_stats: dict
    elasticity: dict
    baselines: dict
    impulse_score: float = Field(ge=0, le=1)
    transaction_count: int = Field(ge=0)
    last_updated: datetime
    
    class Config:
        from_attributes = True


class SimulationRequest(BaseModel):
    """Request schema for spending simulation"""
    scenario_type: Literal["reduction", "increase"] = Field(default="reduction", description="Type of simulation")
    target_percent: float = Field(..., gt=0, le=100, description="Target percentage change")
    target_categories: Optional[list[str]] = Field(None, description="Specific categories to target (None = all categories)")
    time_period_days: int = Field(default=30, gt=0, le=365, description="Analysis period in days")


class ScenarioComparisonRequest(BaseModel):
    """Request schema for comparing multiple spending scenarios"""
    scenario_type: Literal["reduction", "increase"] = Field(default="reduction", description="Type of scenarios to generate")
    time_period_days: int = Field(default=30, gt=0, le=365, description="Analysis period in days")
    num_scenarios: int = Field(default=3, ge=2, le=5, description="Number of scenarios to generate (2-5)")


class ReallocationRequest(BaseModel):
    """Request schema for budget reallocation simulation"""
    reallocations: dict[str, float] = Field(
        ..., 
        description="Category changes as dict (e.g., {'DINING': -500, 'SAVINGS': 500, 'ENTERTAINMENT': -200, 'HEALTHCARE': 200})"
    )
    time_period_days: int = Field(default=30, gt=0, le=365, description="Analysis period in days")
    
    @field_validator('reallocations')
    @classmethod
    def validate_balanced(cls, v):
        total = sum(v.values())
        if abs(total) > 0.01:  # Allow for floating point errors
            raise ValueError(f"Reallocations must sum to zero (net: {total}). Money must be moved, not created or destroyed.")
        return v


class ProjectionRequest(BaseModel):
    """Request schema for future spending projection"""
    projection_months: int = Field(..., ge=1, le=24, description="Number of months to project (1-24)")
    scenario_id: Optional[str] = Field(None, description="Apply a specific scenario (from comparison) for projection")
    behavioral_changes: Optional[dict[str, float]] = Field(
        None,
        description="Expected category changes as percentages (e.g., {'DINING': -15, 'EXERCISE': 10})"
    )
    time_period_days: int = Field(default=30, gt=0, le=365, description="Historical period to analyze")


class CategoryAnalysis(BaseModel):
    """Analysis results for a category"""
    current_monthly: Decimal
    max_reduction_pct: float
    achievable_reduction_pct: float
    monthly_savings: Decimal
    confidence: float = Field(ge=0, le=1)
    difficulty: Literal["easy", "moderate", "challenging"]


class SimulationResponse(BaseModel):
    """Response schema for simulation"""
    scenario_type: str
    target_percent: float
    achievable_percent: float
    baseline_monthly: Decimal
    projected_monthly: Decimal
    total_change: Decimal
    annual_impact: Decimal
    feasibility: Literal["highly_achievable", "achievable", "challenging", "unrealistic"]
    category_breakdown: dict[str, CategoryAnalysis]
    recommendations: list[dict]
    targeted_categories: Optional[list[str]] = None


class ScenarioSummary(BaseModel):
    """Summary of a single scenario for comparison"""
    scenario_id: str
    name: str
    description: str
    scenario_type: str
    target_percent: float
    achievable_percent: float
    baseline_monthly: Decimal
    projected_monthly: Decimal
    total_change: Decimal
    annual_impact: Decimal
    feasibility: Literal["highly_achievable", "achievable", "challenging", "unrealistic"]
    difficulty_score: float = Field(ge=0, le=1, description="Overall difficulty (0=easy, 1=very hard)")
    top_categories: list[str] = Field(description="Top 3 categories affected")
    key_insight: str


class ScenarioComparisonResponse(BaseModel):
    """Response schema for multiple scenario comparison"""
    scenario_type: str
    baseline_monthly: Decimal
    time_period_days: int
    scenarios: list[ScenarioSummary]
    recommended_scenario_id: str
    comparison_chart: dict = Field(description="Data for visualization")
    insights: list[str]


class CategoryReallocation(BaseModel):
    """Reallocation details for a single category"""
    category: str
    current_monthly: Decimal
    change_amount: Decimal
    new_monthly: Decimal
    change_percent: float
    feasibility: Literal["comfortable", "moderate", "difficult", "unrealistic"]
    impact_note: str


class ReallocationResponse(BaseModel):
    """Response schema for budget reallocation simulation"""
    baseline_monthly: Decimal
    projected_monthly: Decimal
    is_balanced: bool
    reallocations: list[CategoryReallocation]
    feasibility_assessment: str
    warnings: list[str]
    recommendations: list[str]
    visual_data: dict


class MonthlyProjection(BaseModel):
    """Projection data for a single month"""
    month: int
    month_label: str
    projected_spending: Decimal
    category_breakdown: dict[str, Decimal]
    cumulative_change: Decimal
    confidence: float = Field(ge=0, le=1)


class ProjectionResponse(BaseModel):
    """Response schema for future spending projection"""
    baseline_monthly: Decimal
    projection_months: int
    monthly_projections: list[MonthlyProjection]
    total_projected: Decimal
    total_baseline: Decimal
    cumulative_change: Decimal
    annual_impact: Decimal
    trend_analysis: str
    confidence_level: str
    key_insights: list[str]
    projection_chart: dict


# PydanticAI specific schemas
class CategorizationContext(BaseModel):
    """Context for LLM categorization"""
    merchant: str
    amount: Decimal
    raw_message: Optional[str] = None
    transaction_type: Literal["debit", "credit"]


class CategorizationResult(BaseModel):
    """Result from LLM categorization"""
    category: str = Field(..., description="The spending category")
    confidence: float = Field(..., ge=0, le=1, description="Confidence score")
    reasoning: Optional[str] = Field(None, description="Brief explanation of categorization")
    
    @field_validator('category')
    @classmethod
    def validate_category(cls, v):
        from app.utils.constants import ALL_CATEGORIES
        if v not in ALL_CATEGORIES:
            raise ValueError(f"Invalid category. Must be one of {ALL_CATEGORIES}")
        return v