"""
Helper functions for simulation scenarios.
Includes scenario generation, difficulty calculation, and insight generation.
"""

from typing import Dict, List, Optional
from app.utils.constants import DISCRETIONARY_CATEGORIES, ESSENTIAL_CATEGORIES
from app.schemas.simulation_schemas import CategoryAnalysis, ScenarioSummary


def generate_recommendations(
    category_analysis: Dict[str, CategoryAnalysis], 
    impulse_score: float,
    scenario_type: str,
    target_categories: Optional[List[str]] = None,
    income_stats: Optional[Dict] = None
) -> list[dict]:
    """
    Generate actionable recommendations for freelancers/gig workers.
    Now includes income-aware advice.
    """
    from app.utils.constants import FREELANCER_CATEGORIES, FLEXIBLE_CATEGORIES
    
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
        
        # Freelancer-specific: Check if income is variable
        if income_stats:
            volatility = income_stats.get('volatility_coefficient', 0)
            if volatility > 0.4:
                recommendations.append({
                    "category": "INCOME_VARIABILITY",
                    "action": "With variable income, prioritize building a 3-6 month emergency fund",
                    "potential_impact": 0,
                    "difficulty": "moderate",
                    "type": "freelancer_advice"
                })
            
            # Check if flexible categories exist
            for category in category_analysis:
                if category in FLEXIBLE_CATEGORIES:
                    recommendations.append({
                        "category": category,
                        "action": f"Adjust {category.lower()} based on monthly income - reduce in lean months",
                        "potential_impact": float(category_analysis[category].monthly_savings),
                        "difficulty": "easy",
                        "type": "freelancer_advice"
                    })
                    break  # Add only one flexible category recommendation
    
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
                elif category in FREELANCER_CATEGORIES:
                    action = f"Investing in {category.lower()} could improve future income - increase by {data.achievable_reduction_pct}%"
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
        
        # Freelancer-specific: Encourage business investment in good months
        if income_stats:
            avg_income = income_stats.get('mean', 0)
            recommendations.append({
                "category": "FREELANCER_STRATEGY",
                "action": f"In months with above-average income (>${avg_income:.0f}), consider investing in business growth or emergency fund",
                "potential_impact": 0,
                "difficulty": "easy",
                "type": "freelancer_advice"
            })
    
    return recommendations


def generate_reduction_scenarios(
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


def generate_increase_scenarios(
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


def calculate_difficulty_score(
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


def select_recommended_scenario(
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


def generate_comparison_insights(
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
