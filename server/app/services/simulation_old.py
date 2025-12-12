from datetime import datetime, timedelta
from typing import Dict, List, Optional
from decimal import Decimal
from sqlalchemy.orm import Session
from app.models.transactions import Transaction
from app.models.behaviour import BehaviourModel
from app.utils.constants import DISCRETIONARY_CATEGORIES, ESSENTIAL_CATEGORIES, ALL_CATEGORIES
from app.schemas.transaction_schemas import (
    SimulationResponse, CategoryAnalysis, 
    ScenarioComparisonResponse, ScenarioSummary
)

class SimulationService:
    """Handles what-if scenario simulations"""
    
    @staticmethod
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
            confidence = min(1.0, (count / 20) * (1 - variance / (mean_spending ** 2 + 1)))
            
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
        
        # Calculate results
        if scenario_type == "reduction":
            projected_total = baseline_total - total_achievable_change
        else:  # increase
            projected_total = baseline_total + total_achievable_change
        
        actual_change_pct = (total_achievable_change / baseline_total * 100) if baseline_total > 0 else 0
        
        # Generate recommendations
        recommendations = _generate_recommendations(
            category_breakdown, 
            model.impulse_score, 
            scenario_type,
            target_categories
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


    @staticmethod
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
        from app.schemas.transaction_schemas import ReallocationResponse, CategoryReallocation
        
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
        
        # Validate all categories exist
        for category in reallocations.keys():
            if category not in stats and category != "SAVINGS" and category != "OTHER":
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
        from app.schemas.transaction_schemas import ProjectionResponse, MonthlyProjection
        from datetime import datetime
        from calendar import month_name
        
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
                import random
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
    
    @staticmethod
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
            scenario_configs = _generate_reduction_scenarios(num_scenarios, stats, elasticity_map)
        else:
            scenario_configs = _generate_increase_scenarios(num_scenarios, stats, elasticity_map)
        
        # Run simulation for each scenario
        scenarios = []
        for config in scenario_configs:
            result = SimulationService.simulate_spending_scenario(
                db=db,
                user_id=user_id,
                scenario_type=scenario_type,
                target_percent=config["target_percent"],
                time_period_days=time_period_days,
                target_categories=config.get("target_categories")
            )
            
            # Calculate difficulty score
            difficulty_score = _calculate_difficulty_score(
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
        recommended = _select_recommended_scenario(scenarios, scenario_type)
        
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
        insights = _generate_comparison_insights(scenarios, scenario_type, model.impulse_score)
        
        return ScenarioComparisonResponse(
            scenario_type=scenario_type,
            baseline_monthly=Decimal(str(baseline_total)),
            time_period_days=time_period_days,
            scenarios=scenarios,
            recommended_scenario_id=recommended,
            comparison_chart=comparison_chart,
            insights=insights
        )


def _generate_recommendations(
    category_analysis: Dict[str, CategoryAnalysis], 
    impulse_score: float,
    scenario_type: str,
    target_categories: Optional[List[str]] = None
) -> list[dict]:
    """Generate actionable recommendations"""
    recommendations = []
    
    if scenario_type == "reduction":
        # Sort by easiest savings first
        sorted_cats = sorted(
            category_analysis.items(),
            key=lambda x: x[1].achievable_reduction_pct,
            reverse=True
        )
        
        for category, data in sorted_cats[:3]:
            if data.monthly_savings > 100:
                recommendations.append({
                    "category": category,
                    "action": f"Reduce {category.lower()} spending by {data.achievable_reduction_pct}%",
                    "potential_impact": float(data.monthly_savings),
                    "difficulty": data.difficulty,
                    "type": "reduction"
                })
        
        if impulse_score > 0.6:
            recommendations.append({
                "category": "IMPULSE_CONTROL",
                "action": "Focus on reducing late-night and weekend purchases",
                "potential_impact": float(impulse_score * 500),
                "difficulty": "moderate",
                "type": "behavioral"
            })
    
    else:  # scenario_type == "increase"
        # Sort by categories where increase is most achievable
        sorted_cats = sorted(
            category_analysis.items(),
            key=lambda x: x[1].achievable_reduction_pct,
            reverse=True
        )
        
        for category, data in sorted_cats[:3]:
            if data.monthly_savings > 50:
                if category in DISCRETIONARY_CATEGORIES:
                    action = f"You could comfortably increase {category.lower()} spending by {data.achievable_reduction_pct}%"
                else:
                    action = f"Increasing {category.lower()} by {data.achievable_reduction_pct}% is feasible but monitor carefully"
                
                recommendations.append({
                    "category": category,
                    "action": action,
                    "potential_impact": float(data.monthly_savings),
                    "difficulty": data.difficulty,
                    "type": "increase"
                })
        
        if target_categories:
            recommendations.append({
                "category": "BUDGETING",
                "action": f"Set up budget tracking for {', '.join(target_categories)} to monitor increased spending",
                "potential_impact": 0,
                "difficulty": "easy",
                "type": "monitoring"
            })
    
    return recommendations


def _generate_reduction_scenarios(
    num_scenarios: int,
    stats: Dict,
    elasticity_map: Dict
) -> List[Dict]:
    """Generate reduction scenario configurations"""
    
    # Identify high-flexibility categories (discretionary with high elasticity)
    flexible_categories = [
        cat for cat in stats.keys()
        if cat in DISCRETIONARY_CATEGORIES and elasticity_map.get(cat, 0) > 0.5
    ]
    
    configs = [
        {
            "id": "conservative",
            "name": "Conservative Reduction",
            "description": "Small, easily achievable cuts across flexible spending",
            "target_percent": 10.0,
            "target_categories": flexible_categories[:3] if flexible_categories else None,
            "key_insight": "Low effort, quick wins in discretionary spending"
        },
        {
            "id": "moderate",
            "name": "Moderate Reduction",
            "description": "Balanced approach targeting multiple categories",
            "target_percent": 20.0,
            "target_categories": None,
            "key_insight": "Sustainable long-term savings with moderate lifestyle changes"
        },
        {
            "id": "aggressive",
            "name": "Aggressive Reduction",
            "description": "Maximum savings requiring significant lifestyle changes",
            "target_percent": 35.0,
            "target_categories": None,
            "key_insight": "Substantial savings but requires commitment and planning"
        }
    ]
    
    if num_scenarios == 4:
        configs.insert(1, {
            "id": "targeted",
            "name": "Targeted Reduction",
            "description": "Focus on your most flexible spending categories",
            "target_percent": 25.0,
            "target_categories": flexible_categories if flexible_categories else None,
            "key_insight": "Maximize impact by focusing on high-flexibility categories"
        })
    elif num_scenarios == 5:
        configs.insert(1, {
            "id": "minimal",
            "name": "Minimal Reduction",
            "description": "Smallest possible cuts for those starting their journey",
            "target_percent": 5.0,
            "target_categories": flexible_categories[:2] if flexible_categories else None,
            "key_insight": "Perfect starting point with minimal disruption"
        })
        configs.insert(3, {
            "id": "targeted",
            "name": "Targeted Reduction",
            "description": "Focus on your most flexible spending categories",
            "target_percent": 25.0,
            "target_categories": flexible_categories if flexible_categories else None,
            "key_insight": "Maximize impact by focusing on high-flexibility categories"
        })
    elif num_scenarios == 2:
        configs = [configs[0], configs[2]]  # Conservative and aggressive only
    
    return configs[:num_scenarios]


def _generate_increase_scenarios(
    num_scenarios: int,
    stats: Dict,
    elasticity_map: Dict
) -> List[Dict]:
    """Generate increase scenario configurations"""
    
    # Identify discretionary categories for comfortable increase
    discretionary = [
        cat for cat in stats.keys()
        if cat in DISCRETIONARY_CATEGORIES
    ]
    
    configs = [
        {
            "id": "modest",
            "name": "Modest Increase",
            "description": "Small increase in lifestyle spending",
            "target_percent": 10.0,
            "target_categories": discretionary[:2] if discretionary else None,
            "key_insight": "Slight improvement in quality of life with minimal financial impact"
        },
        {
            "id": "comfortable",
            "name": "Comfortable Increase",
            "description": "Noticeable lifestyle upgrade",
            "target_percent": 20.0,
            "target_categories": None,
            "key_insight": "Balanced increase across spending for improved lifestyle"
        },
        {
            "id": "significant",
            "name": "Significant Increase",
            "description": "Major lifestyle enhancement",
            "target_percent": 35.0,
            "target_categories": None,
            "key_insight": "Substantial increase requiring higher income or savings adjustment"
        }
    ]
    
    if num_scenarios == 4:
        configs.insert(2, {
            "id": "targeted_luxury",
            "name": "Targeted Luxury",
            "description": "Focus increase on entertainment and dining",
            "target_percent": 30.0,
            "target_categories": discretionary if discretionary else None,
            "key_insight": "Splurge on experiences while keeping essentials stable"
        })
    elif num_scenarios == 5:
        configs.insert(1, {
            "id": "minimal",
            "name": "Minimal Increase",
            "description": "Tiny boost to discretionary spending",
            "target_percent": 5.0,
            "target_categories": discretionary[:1] if discretionary else None,
            "key_insight": "Test waters with small lifestyle improvement"
        })
        configs.insert(3, {
            "id": "targeted_luxury",
            "name": "Targeted Luxury",
            "description": "Focus increase on entertainment and dining",
            "target_percent": 30.0,
            "target_categories": discretionary if discretionary else None,
            "key_insight": "Splurge on experiences while keeping essentials stable"
        })
    elif num_scenarios == 2:
        configs = [configs[0], configs[2]]  # Modest and significant only
    
    return configs[:num_scenarios]


def _calculate_difficulty_score(
    category_breakdown: Dict[str, CategoryAnalysis],
    achievable_percent: float,
    target_percent: float
) -> float:
    """Calculate overall difficulty score (0=easy, 1=very hard)"""
    
    if not category_breakdown:
        return 0.5
    
    # Factor 1: Achievement gap
    achievement_ratio = achievable_percent / target_percent if target_percent > 0 else 1.0
    gap_penalty = 1.0 - achievement_ratio
    
    # Factor 2: Category difficulty average
    difficulty_map = {"easy": 0.2, "moderate": 0.5, "challenging": 0.8}
    avg_difficulty = sum(
        difficulty_map[cat.difficulty] for cat in category_breakdown.values()
    ) / len(category_breakdown)
    
    # Factor 3: Confidence (inverse)
    avg_confidence = sum(
        float(cat.confidence) for cat in category_breakdown.values()
    ) / len(category_breakdown)
    confidence_penalty = 1.0 - avg_confidence
    
    # Weighted combination
    difficulty = (gap_penalty * 0.4) + (avg_difficulty * 0.4) + (confidence_penalty * 0.2)
    
    return min(1.0, max(0.0, difficulty))


def _select_recommended_scenario(
    scenarios: List[ScenarioSummary],
    scenario_type: str
) -> str:
    """Select the best recommended scenario based on feasibility and impact"""
    
    # Score each scenario
    scored = []
    for scenario in scenarios:
        # Base score on feasibility
        feasibility_scores = {
            "highly_achievable": 1.0,
            "achievable": 0.8,
            "challenging": 0.5,
            "unrealistic": 0.2
        }
        score = feasibility_scores[scenario.feasibility]
        
        # Bonus for good achievement ratio
        achievement_ratio = scenario.achievable_percent / scenario.target_percent
        score += achievement_ratio * 0.3
        
        # Penalty for high difficulty
        score -= scenario.difficulty_score * 0.2
        
        # Bonus for impact (but not too extreme)
        if scenario_type == "reduction":
            # Prefer meaningful savings without being too aggressive
            if 15 <= scenario.achievable_percent <= 25:
                score += 0.2
        else:
            # Prefer moderate increases
            if 10 <= scenario.achievable_percent <= 20:
                score += 0.2
        
        scored.append((scenario.scenario_id, score))
    
    # Return scenario with highest score
    return max(scored, key=lambda x: x[1])[0]


def _generate_comparison_insights(
    scenarios: List[ScenarioSummary],
    scenario_type: str,
    impulse_score: float
) -> List[str]:
    """Generate insights from scenario comparison"""
    
    insights = []
    
    # Achievement analysis
    avg_achievement = sum(s.achievable_percent for s in scenarios) / len(scenarios)
    if scenario_type == "reduction":
        if avg_achievement >= 20:
            insights.append(f"You have strong potential for savings with an average achievable reduction of {avg_achievement:.1f}%")
        else:
            insights.append(f"Your spending is relatively efficient with moderate reduction potential of {avg_achievement:.1f}%")
    else:
        insights.append(f"You can comfortably increase spending by an average of {avg_achievement:.1f}% across scenarios")
    
    # Difficulty comparison
    easiest = min(scenarios, key=lambda s: s.difficulty_score)
    hardest = max(scenarios, key=lambda s: s.difficulty_score)
    insights.append(f"Easiest path: {easiest.name} (difficulty: {easiest.difficulty_score:.0%})")
    
    # Impact analysis
    max_impact = max(scenarios, key=lambda s: float(s.annual_impact))
    if scenario_type == "reduction":
        insights.append(f"Maximum annual savings potential: ${float(max_impact.annual_impact):,.0f} with {max_impact.name}")
    else:
        insights.append(f"Maximum annual spending increase: ${float(max_impact.annual_impact):,.0f} with {max_impact.name}")
    
    # Behavioral insight
    if impulse_score > 0.6 and scenario_type == "reduction":
        insights.append("Your impulse score suggests significant savings opportunity through better spending habits")
    
    # Category insight
    all_top_categories = {}
    for scenario in scenarios:
        for cat in scenario.top_categories:
            all_top_categories[cat] = all_top_categories.get(cat, 0) + 1
    
    if all_top_categories:
        most_common = max(all_top_categories.items(), key=lambda x: x[1])
        action = "reduce" if scenario_type == "reduction" else "increase"
        insights.append(f"{most_common[0]} appears in {most_common[1]} scenarios as a key area to {action}")
    
    return insights