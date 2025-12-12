"""
Unit tests for income tracking and freelancer-specific logic.

Tests cover:
- Income statistics tracking
- Income/expense ratio calculations
- Income pattern analysis
- Timezone handling
- Edge cases (zero income, single payment, etc.)
"""
import pytest
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from app.services.statistics import StatisticsService
from app.utils.datetime_utils import utc_now, ensure_utc


class TestIncomeTracking:
    """Test income statistics tracking."""
    
    def test_welford_stats_single_value(self):
        """Test Welford algorithm with single value."""
        stats_service = StatisticsService()
        stats = {
            "count": 0, "sum": 0.0, "mean": 0.0,
            "variance": 0.0, "std_dev": 0.0, "m2": 0.0,
            "min": 0, "max": 0
        }
        
        result = stats_service.update_welford_stats(stats, 1000.0)
        
        assert result["count"] == 1
        assert result["mean"] == 1000.0
        assert result["variance"] == 0.0
        assert result["std_dev"] == 0.0
        assert result["min"] == 1000.0
        assert result["max"] == 1000.0
    
    def test_welford_stats_multiple_values(self):
        """Test Welford algorithm with multiple values."""
        stats_service = StatisticsService()
        stats = {
            "count": 0, "sum": 0.0, "mean": 0.0,
            "variance": 0.0, "std_dev": 0.0, "m2": 0.0,
            "min": 0, "max": 0
        }
        
        # Add values: 1000, 2000, 3000
        stats = stats_service.update_welford_stats(stats, 1000.0)
        stats = stats_service.update_welford_stats(stats, 2000.0)
        stats = stats_service.update_welford_stats(stats, 3000.0)
        
        assert stats["count"] == 3
        assert stats["mean"] == 2000.0
        assert stats["min"] == 1000.0
        assert stats["max"] == 3000.0
        assert stats["std_dev"] > 0  # Should have variance
    
    def test_income_expense_ratio_good_sustainability(self):
        """Test ratio calculation for sustainable freelancer income."""
        stats_service = StatisticsService()
        
        income_stats = {
            "mean": 5000.0,
            "std_dev": 1000.0,
            "min": 3000.0,
            "max": 7000.0
        }
        
        expense_stats = {
            "HOUSING": {"mean": 1200.0},
            "GROCERIES": {"mean": 400.0},
            "UTILITIES": {"mean": 200.0},
            "BUSINESS_EXPENSE": {"mean": 300.0}
        }
        
        result = stats_service.calculate_income_expense_ratio(income_stats, expense_stats)
        
        assert result["avg_income"] == 5000.0
        assert result["avg_expenses"] == 2100.0
        assert result["avg_ratio"] > 2.0  # Good ratio
        assert result["sustainability"] in ["excellent", "good"]
        assert result["risk_level"] in ["low"]
    
    def test_income_expense_ratio_challenging_sustainability(self):
        """Test ratio calculation for challenging freelancer situation."""
        stats_service = StatisticsService()
        
        income_stats = {
            "mean": 3000.0,
            "std_dev": 1500.0,  # High volatility
            "min": 800.0,
            "max": 5000.0
        }
        
        expense_stats = {
            "HOUSING": {"mean": 1200.0},
            "GROCERIES": {"mean": 400.0},
            "UTILITIES": {"mean": 200.0},
            "BUSINESS_EXPENSE": {"mean": 500.0},
            "DINING": {"mean": 300.0}
        }
        
        result = stats_service.calculate_income_expense_ratio(income_stats, expense_stats)
        
        assert result["avg_income"] == 3000.0
        assert result["avg_expenses"] == 2600.0
        # Worst case: 3000 - 1.5*1500 = 750
        assert result["worst_case_ratio"] < 1.0  # Worst case is negative
        assert result["sustainability"] in ["challenging", "critical"]
        assert result["risk_level"] in ["high", "very_high"]
        assert result["recommended_buffer"] > 0
    
    def test_income_expense_ratio_zero_income(self):
        """Test ratio calculation handles zero income gracefully."""
        stats_service = StatisticsService()
        
        income_stats = {
            "mean": 0.0,
            "std_dev": 0.0,
            "min": 0.0,
            "max": 0.0
        }
        
        expense_stats = {
            "HOUSING": {"mean": 1200.0}
        }
        
        result = stats_service.calculate_income_expense_ratio(income_stats, expense_stats)
        
        assert result["avg_income"] == 0.0
        assert result["avg_ratio"] == 0.0
        assert result["sustainability"] == "critical"
        assert result["risk_level"] == "very_high"
    
    def test_analyze_income_patterns_good_diversity(self):
        """Test income pattern analysis with good client diversity."""
        stats_service = StatisticsService()
        
        income_stats = {
            "count": 10,
            "mean": 2500.0,
            "std_dev": 500.0,
            "volatility_coefficient": 0.2,
            "income_frequency_days": [7, 14, 10, 8, 12, 9, 11],
            "sources": {
                "Client A": {"count": 3, "total": 3000.0},
                "Client B": {"count": 2, "total": 2000.0},
                "Client C": {"count": 2, "total": 2000.0},
                "Client D": {"count": 2, "total": 2000.0},
                "Client E": {"count": 1, "total": 1000.0}
            }
        }
        
        result = stats_service.analyze_income_patterns(income_stats)
        
        assert result["income_sources"] == 5
        assert result["diversity_level"] in ["excellent", "good"]
        assert result["stability"] == "stable"
        assert result["payment_frequency_days"] > 0
        assert result["longest_gap_days"] == 14
        assert result["shortest_gap_days"] == 7
    
    def test_analyze_income_patterns_low_diversity(self):
        """Test income pattern analysis with low client diversity (risky)."""
        stats_service = StatisticsService()
        
        income_stats = {
            "count": 10,
            "mean": 2500.0,
            "std_dev": 1500.0,
            "volatility_coefficient": 0.6,  # High volatility
            "income_frequency_days": [30, 45, 28, 32],
            "sources": {
                "Client A": {"count": 8, "total": 20000.0},  # 80% from one client
                "Client B": {"count": 2, "total": 5000.0}
            }
        }
        
        result = stats_service.analyze_income_patterns(income_stats)
        
        assert result["income_sources"] == 2
        assert result["diversity_level"] in ["low", "moderate"]
        assert result["stability"] == "highly_variable"
        assert result["client_concentration"] > 0.5  # High concentration
    
    def test_analyze_income_patterns_no_data(self):
        """Test income pattern analysis with no income data."""
        stats_service = StatisticsService()
        
        income_stats = {
            "count": 0,
            "mean": 0.0,
            "std_dev": 0.0,
            "volatility_coefficient": 0.0,
            "income_frequency_days": [],
            "sources": {}
        }
        
        result = stats_service.analyze_income_patterns(income_stats)
        
        assert result["income_sources"] == 0
        assert result["payment_frequency_days"] == 0
        assert result["longest_gap_days"] == 0
        assert result["shortest_gap_days"] == 0


class TestDatetimeUtils:
    """Test timezone utilities."""
    
    def test_utc_now_returns_aware_datetime(self):
        """Test utc_now returns timezone-aware datetime."""
        from app.utils.datetime_utils import utc_now
        
        result = utc_now()
        
        assert result.tzinfo is not None
        assert result.tzinfo == timezone.utc
    
    def test_ensure_utc_with_naive_datetime(self):
        """Test ensure_utc adds UTC timezone to naive datetime."""
        from app.utils.datetime_utils import ensure_utc
        
        naive_dt = datetime(2025, 1, 15, 10, 30, 0)
        result = ensure_utc(naive_dt)
        
        assert result.tzinfo is not None
        assert result.tzinfo == timezone.utc
        assert result.year == 2025
        assert result.month == 1
        assert result.day == 15
    
    def test_ensure_utc_with_aware_datetime(self):
        """Test ensure_utc preserves already-UTC datetime."""
        from app.utils.datetime_utils import ensure_utc
        
        aware_dt = datetime(2025, 1, 15, 10, 30, 0, tzinfo=timezone.utc)
        result = ensure_utc(aware_dt)
        
        assert result.tzinfo == timezone.utc
        assert result == aware_dt
    
    def test_ensure_utc_converts_to_utc(self):
        """Test ensure_utc converts non-UTC timezone to UTC."""
        from app.utils.datetime_utils import ensure_utc
        from datetime import timezone, timedelta
        
        # Create datetime in UTC+5
        other_tz = timezone(timedelta(hours=5))
        other_dt = datetime(2025, 1, 15, 15, 30, 0, tzinfo=other_tz)
        
        result = ensure_utc(other_dt)
        
        assert result.tzinfo == timezone.utc
        # Should be 5 hours earlier in UTC
        assert result.hour == 10
    
    def test_safe_isoformat_with_naive_datetime(self):
        """Test safe_isoformat handles naive datetime."""
        from app.utils.datetime_utils import safe_isoformat
        
        naive_dt = datetime(2025, 1, 15, 10, 30, 0)
        result = safe_isoformat(naive_dt)
        
        assert result is not None
        assert "2025-01-15" in result
        assert "+00:00" in result or "Z" in result or result.endswith("+00:00")
    
    def test_safe_isoformat_with_none(self):
        """Test safe_isoformat handles None."""
        from app.utils.datetime_utils import safe_isoformat
        
        result = safe_isoformat(None)
        
        assert result is None
    
    def test_safe_fromisoformat_valid_string(self):
        """Test safe_fromisoformat parses valid ISO string."""
        from app.utils.datetime_utils import safe_fromisoformat
        
        iso_string = "2025-01-15T10:30:00+00:00"
        result = safe_fromisoformat(iso_string)
        
        assert result is not None
        assert result.tzinfo == timezone.utc
        assert result.year == 2025
        assert result.month == 1
        assert result.day == 15
    
    def test_safe_fromisoformat_none(self):
        """Test safe_fromisoformat handles None."""
        from app.utils.datetime_utils import safe_fromisoformat
        
        result = safe_fromisoformat(None)
        
        assert result is None
    
    def test_safe_fromisoformat_invalid_string(self):
        """Test safe_fromisoformat handles invalid string."""
        from app.utils.datetime_utils import safe_fromisoformat
        
        result = safe_fromisoformat("invalid-date")
        
        assert result is None


if __name__ == "__main__":
    # Run tests with pytest
    pytest.main([__file__, "-v"])
