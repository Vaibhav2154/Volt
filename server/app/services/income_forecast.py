"""
Income forecasting and runway calculations for freelancers/gig workers.

Provides:
- Simple exponential smoothing for next-month income prediction
- Runway calculation (months until savings depleted)
- Income trend analysis
"""
from typing import Dict, Optional, Tuple
import math


class IncomeForecastService:
    """Service for forecasting income and calculating financial runway."""
    
    @staticmethod
    def exponential_smoothing_forecast(
        income_history: list[float],
        alpha: float = 0.3
    ) -> Tuple[float, float]:
        """
        Simple exponential smoothing forecast for next period.
        
        Args:
            income_history: List of historical income values (most recent last)
            alpha: Smoothing factor (0-1). Lower = more smoothing, higher = more responsive
            
        Returns:
            Tuple of (forecast, confidence_score)
        """
        if not income_history:
            return 0.0, 0.0
        
        if len(income_history) == 1:
            return income_history[0], 0.3  # Low confidence with single data point
        
        # Initialize with first value
        smoothed = income_history[0]
        
        # Apply exponential smoothing
        for value in income_history[1:]:
            smoothed = alpha * value + (1 - alpha) * smoothed
        
        # Forecast is the smoothed value
        forecast = smoothed
        
        # Confidence based on data points and consistency
        data_confidence = min(len(income_history) / 12, 1.0)  # More data = more confidence
        
        # Calculate coefficient of variation for consistency
        if len(income_history) >= 3:
            mean = sum(income_history) / len(income_history)
            variance = sum((x - mean) ** 2 for x in income_history) / len(income_history)
            std_dev = math.sqrt(variance)
            cv = std_dev / mean if mean > 0 else 1.0
            consistency_confidence = max(0, 1 - cv)  # Lower CV = higher confidence
        else:
            consistency_confidence = 0.5
        
        # Combined confidence
        confidence = (data_confidence * 0.6 + consistency_confidence * 0.4)
        
        return forecast, confidence
    
    @staticmethod
    def calculate_runway(
        current_balance: float,
        avg_income: float,
        avg_expenses: float,
        income_volatility: float = 0.0,
        buffer_multiplier: float = 1.5
    ) -> Dict:
        """
        Calculate financial runway for freelancer.
        
        Args:
            current_balance: Current savings/cash balance
            avg_income: Average monthly income
            avg_expenses: Average monthly expenses
            income_volatility: Income volatility coefficient (std_dev / mean)
            buffer_multiplier: Safety multiplier for volatile income
            
        Returns:
            Dict with runway analysis
        """
        # Monthly burn rate (worst case)
        net_monthly = avg_income - avg_expenses
        
        # Adjust for volatility - assume worst case income scenario
        worst_case_income = max(0, avg_income - (income_volatility * avg_income * buffer_multiplier))
        worst_case_net = worst_case_income - avg_expenses
        
        # Calculate runway
        if net_monthly >= 0:
            # Positive cash flow - no runway concern
            runway_months = float('inf')
            worst_case_runway = float('inf') if worst_case_net >= 0 else current_balance / abs(worst_case_net)
        else:
            # Negative cash flow - calculate runway
            runway_months = current_balance / abs(net_monthly) if net_monthly < 0 else float('inf')
            worst_case_runway = current_balance / abs(worst_case_net) if worst_case_net < 0 else float('inf')
        
        # Risk assessment
        if worst_case_runway == float('inf'):
            risk_level = "no_risk"
            risk_message = "Sustainable - positive cash flow even in worst case"
        elif worst_case_runway >= 12:
            risk_level = "low"
            risk_message = f"Healthy runway of {worst_case_runway:.1f} months in worst case"
        elif worst_case_runway >= 6:
            risk_level = "moderate"
            risk_message = f"Adequate runway of {worst_case_runway:.1f} months, but monitor closely"
        elif worst_case_runway >= 3:
            risk_level = "high"
            risk_message = f"Limited runway of {worst_case_runway:.1f} months - urgent action needed"
        else:
            risk_level = "critical"
            risk_message = f"Critical - only {worst_case_runway:.1f} months runway remaining"
        
        # Recommended emergency fund
        recommended_emergency_fund = abs(worst_case_net) * 6 if worst_case_net < 0 else avg_expenses * 3
        
        return {
            'current_balance': round(current_balance, 2),
            'avg_monthly_net': round(net_monthly, 2),
            'worst_case_monthly_net': round(worst_case_net, 2),
            'runway_months': round(runway_months, 1) if runway_months != float('inf') else None,
            'worst_case_runway_months': round(worst_case_runway, 1) if worst_case_runway != float('inf') else None,
            'risk_level': risk_level,
            'risk_message': risk_message,
            'recommended_emergency_fund': round(recommended_emergency_fund, 2),
            'emergency_fund_gap': round(max(0, recommended_emergency_fund - current_balance), 2)
        }
    
    @staticmethod
    def analyze_income_trend(income_history: list[float]) -> Dict:
        """
        Analyze income trend over time.
        
        Args:
            income_history: List of historical income values (chronological)
            
        Returns:
            Dict with trend analysis
        """
        if len(income_history) < 2:
            return {
                'trend': 'insufficient_data',
                'trend_strength': 0.0,
                'growth_rate': 0.0,
                'message': 'Need at least 2 months of data'
            }
        
        # Simple linear regression for trend
        n = len(income_history)
        x = list(range(n))
        y = income_history
        
        # Calculate slope
        x_mean = sum(x) / n
        y_mean = sum(y) / n
        
        numerator = sum((x[i] - x_mean) * (y[i] - y_mean) for i in range(n))
        denominator = sum((x[i] - x_mean) ** 2 for i in range(n))
        
        slope = numerator / denominator if denominator != 0 else 0
        
        # Normalize slope as percentage growth per month
        growth_rate = (slope / y_mean * 100) if y_mean > 0 else 0
        
        # Trend classification
        if abs(growth_rate) < 2:
            trend = 'stable'
            trend_strength = abs(growth_rate) / 2
        elif growth_rate >= 2:
            trend = 'growing'
            trend_strength = min(growth_rate / 10, 1.0)
        else:
            trend = 'declining'
            trend_strength = min(abs(growth_rate) / 10, 1.0)
        
        # Generate message
        if trend == 'growing':
            message = f"Income growing at {abs(growth_rate):.1f}% per month - positive trajectory"
        elif trend == 'declining':
            message = f"Income declining at {abs(growth_rate):.1f}% per month - needs attention"
        else:
            message = "Income stable with minimal variation"
        
        return {
            'trend': trend,
            'trend_strength': round(trend_strength, 2),
            'growth_rate': round(growth_rate, 2),
            'message': message
        }
