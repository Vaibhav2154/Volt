from pydantic_ai import Agent
from pydantic_ai.models.google import GoogleModel
from pydantic_ai.providers.google import GoogleProvider
from app.core.config import settings
from app.schemas.simulation_schemas import ScenarioComparisonResponse, SimulationResponse
from typing import Union
import json


class RefinementService:
    def __init__(self):
        self.provider = GoogleProvider(api_key=settings.gemini_api_key)
        self.model = GoogleModel("gemini-2.5-flash", provider=self.provider)

    async def refine_insight(self, data: Union[ScenarioComparisonResponse, SimulationResponse]) -> str:
        """Generate a concise 2-4 sentence insight from simulation data using Gemini."""
        
        agent = Agent(
            model=self.model,
            output_type=str,
            system_prompt=(
                "You are a financial insights expert. Analyze the provided simulation or comparison data "
                "and generate a concise, actionable insight in 2-4 sentences formatted in markdown. "
                "Use markdown formatting like **bold** for emphasis, and organize the content clearly. "
                "Focus on the most important findings, feasibility, and practical recommendations. "
                "Be clear, direct, and use natural language. Avoid technical jargon and make it easy to "
                "understand for everyday users."
            )
        )

        # Convert the data to a formatted string for the agent
        if isinstance(data, SimulationResponse):
            prompt = f"""
Analyze this budget simulation:
- Scenario: {data.scenario_type}
- Target: {data.target_percent}% change
- Achievable: {data.achievable_percent}%
- Monthly baseline: ${data.baseline_monthly}
- Projected monthly: ${data.projected_monthly}
- Total change: ${data.total_change}
- Annual impact: ${data.annual_impact}
- Feasibility: {data.feasibility}
- Top categories: {', '.join(data.category_breakdown.keys())}

Provide a clear, actionable insight in 2-4 sentences using markdown formatting.
"""
        else:  # ScenarioComparisonResponse
            scenarios_info = "\n".join([
                f"- {s.name} ({s.scenario_type}): {s.target_percent}% change, {s.feasibility} feasibility, "
                f"${s.total_change} monthly change, affects {', '.join(s.top_categories[:2])}"
                for s in data.scenarios
            ])
            prompt = f"""
Analyze this scenario comparison:
- Baseline monthly: ${data.baseline_monthly}
- Time period: {data.time_period_days} days
- Number of scenarios: {len(data.scenarios)}
- Recommended scenario: {data.recommended_scenario_id}

Scenarios:
{scenarios_info}

Provide a clear, actionable insight in 2-4 sentences comparing these scenarios using markdown formatting.
"""

        response = await agent.run(prompt)
        insight = response.output
        
        return insight
 