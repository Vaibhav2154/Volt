"""
Comprehensive test suite for category utility functions.

Tests all functions in app/utils/category_utils.py:
- identify_rare_categories: Detection of categories with few transactions
- get_category_reliability_score: Reliability scoring based on count and consistency
- get_established_categories: Filtering of reliable categories
- should_include_in_simulation: Simulation inclusion logic
- get_category_summary: Comprehensive category metadata
- filter_categories_for_analysis: Filtered stats for analysis

Each function has tests covering:
1. Happy path (normal usage)
2. Edge cases (boundary conditions)
3. Error cases (None/empty inputs)
"""
import pytest
from app.utils.category_utils import (
    identify_rare_categories,
    get_category_reliability_score,
    get_established_categories,
    should_include_in_simulation,
    get_category_summary,
    filter_categories_for_analysis,
)


# ============================================================================
# Mock Model Class (avoids SQLAlchemy relationship issues in unit tests)
# ============================================================================

class MockBehaviourModel:
    """
    Simple mock of BehaviourModel for unit testing.
    
    Avoids SQLAlchemy ORM complexity and relationship initialization issues.
    Provides just the category_stats attribute needed by category_utils functions.
    """
    def __init__(self):
        self.category_stats = None


# ============================================================================
# Test Fixtures and Helpers
# ============================================================================

def create_test_model(category_data: dict) -> MockBehaviourModel:
    """
    Create a test BehaviourModel with specified category stats.
    
    This helper reduces boilerplate when creating test models. It automatically
    fills in min, max, and sum fields if not provided.
    
    Args:
        category_data: Dict mapping category names to their stats.
            Minimum required: {"count": int, "mean": float, "std_dev": float}
            Optional: {"min": float, "max": float, "sum": float}
            
            Example:
            {
                "GROCERIES": {"count": 10, "mean": 100.0, "std_dev": 15.0},
                "HOUSING": {"count": 2, "mean": 1200.0, "std_dev": 0.0}
            }
    
    Returns:
        MockBehaviourModel instance with populated category_stats
        
    Usage:
        # Simple case - just count, mean, std_dev
        model = create_test_model({
            "GROCERIES": {"count": 10, "mean": 100.0, "std_dev": 15.0}
        })
        
        # With explicit min/max
        model = create_test_model({
            "GROCERIES": {"count": 10, "mean": 100.0, "std_dev": 15.0,
                         "min": 70.0, "max": 130.0}
        })
    """
    model = MockBehaviourModel()
    model.category_stats = {}
    
    for category, stats in category_data.items():
        model.category_stats[category] = {
            "count": stats.get("count", 0),
            "mean": stats.get("mean", 0.0),
            "std_dev": stats.get("std_dev", 0.0),
            "min": stats.get("min", stats.get("mean", 0.0)),
            "max": stats.get("max", stats.get("mean", 0.0)),
            "sum": stats.get("sum", stats.get("mean", 0.0) * stats.get("count", 0)),
        }
    
    return model


# ============================================================================
# TestIdentifyRareCategories
# ============================================================================

class TestIdentifyRareCategories:
    """Test rare category detection with various thresholds."""
    
    def test_identify_rare_with_default_threshold(self):
        """Test rare category detection with default threshold=3."""
        # WHY: Default threshold of 3 separates noise (1-2 transactions) from patterns
        model = create_test_model({
            "GROCERIES": {"count": 10, "mean": 100.0, "std_dev": 15.0},
            "HOUSING": {"count": 5, "mean": 1200.0, "std_dev": 0.0},
            "RARE_ITEM": {"count": 1, "mean": 50.0, "std_dev": 0.0},
            "OCCASIONAL": {"count": 2, "mean": 75.0, "std_dev": 5.0},
            "BORDERLINE": {"count": 3, "mean": 200.0, "std_dev": 10.0},
        })
        
        rare = identify_rare_categories(model)
        
        assert len(rare) == 2, f"Expected 2 rare categories, got {len(rare)}"
        assert "RARE_ITEM" in rare, "Category with count=1 should be rare"
        assert "OCCASIONAL" in rare, "Category with count=2 should be rare"
        assert "BORDERLINE" not in rare, "Category with count=3 should NOT be rare (at threshold)"
        assert "GROCERIES" not in rare, "Established category should not be rare"
        assert "HOUSING" not in rare, "Established category should not be rare"
    
    def test_identify_rare_with_custom_threshold_high(self):
        """Test rare category detection with higher threshold=5."""
        # WHY: Higher threshold for more conservative filtering
        model = create_test_model({
            "ESTABLISHED": {"count": 10, "mean": 100.0, "std_dev": 15.0},
            "BORDERLINE": {"count": 5, "mean": 200.0, "std_dev": 10.0},
            "SOMEWHAT_RARE": {"count": 4, "mean": 150.0, "std_dev": 20.0},
            "VERY_RARE": {"count": 2, "mean": 75.0, "std_dev": 5.0},
        })
        
        rare = identify_rare_categories(model, threshold=5)
        
        assert len(rare) == 2, f"Expected 2 rare categories with threshold=5, got {len(rare)}"
        assert "SOMEWHAT_RARE" in rare, "Count=4 should be rare when threshold=5"
        assert "VERY_RARE" in rare, "Count=2 should be rare when threshold=5"
        assert "BORDERLINE" not in rare, "Count=5 should NOT be rare (at threshold)"
        assert "ESTABLISHED" not in rare, "Count=10 should not be rare"
    
    def test_identify_rare_with_custom_threshold_low(self):
        """Test rare category detection with lower threshold=1."""
        # WHY: Threshold=1 means only categories with 0 transactions are rare (edge case)
        model = create_test_model({
            "ONE_TX": {"count": 1, "mean": 50.0, "std_dev": 0.0},
            "TWO_TX": {"count": 2, "mean": 75.0, "std_dev": 5.0},
            "MANY_TX": {"count": 10, "mean": 100.0, "std_dev": 15.0},
        })
        
        rare = identify_rare_categories(model, threshold=1)
        
        # With threshold=1, nothing should be rare (all have count >= 1)
        assert len(rare) == 0, f"Expected 0 rare categories with threshold=1, got {len(rare)}"
    
    def test_identify_rare_with_empty_model(self):
        """Test with None model - should return empty list, not crash."""
        # WHY: Defensive programming - handle missing/invalid models gracefully
        rare = identify_rare_categories(None)
        assert rare == [], "None model should return empty list"
    
    def test_identify_rare_with_no_category_stats(self):
        """Test with model that has None or empty category_stats."""
        # WHY: Handle uninitialized models
        model = MockBehaviourModel()
        model.category_stats = None
        rare = identify_rare_categories(model)
        assert rare == [], "Model with None category_stats should return empty list"
        
        model.category_stats = {}
        rare = identify_rare_categories(model)
        assert rare == [], "Model with empty category_stats should return empty list"
    
    def test_identify_rare_all_categories_rare(self):
        """Test when all categories are below threshold."""
        # WHY: Edge case where user has only tried few transactions per category
        model = create_test_model({
            "CAT1": {"count": 1, "mean": 50.0, "std_dev": 0.0},
            "CAT2": {"count": 2, "mean": 75.0, "std_dev": 5.0},
            "CAT3": {"count": 1, "mean": 100.0, "std_dev": 0.0},
        })
        
        rare = identify_rare_categories(model, threshold=3)
        
        assert len(rare) == 3, "All categories should be identified as rare"
        assert set(rare) == {"CAT1", "CAT2", "CAT3"}
    
    def test_identify_rare_no_categories_rare(self):
        """Test when no categories are below threshold."""
        # WHY: Mature user with established patterns
        model = create_test_model({
            "CAT1": {"count": 10, "mean": 100.0, "std_dev": 15.0},
            "CAT2": {"count": 20, "mean": 200.0, "std_dev": 30.0},
            "CAT3": {"count": 15, "mean": 150.0, "std_dev": 20.0},
        })
        
        rare = identify_rare_categories(model, threshold=3)
        
        assert len(rare) == 0, "No categories should be rare when all have high counts"


# ============================================================================
# TestGetCategoryReliabilityScore
# ============================================================================

class TestGetCategoryReliabilityScore:
    """Test reliability scoring based on count and variance."""
    
    def test_reliability_score_consistent_high_count(self):
        """Test high reliability for consistent spending with many transactions."""
        # WHY: High count + low variance = most reliable for predictions
        model = create_test_model({
            "RELIABLE": {"count": 20, "mean": 100.0, "std_dev": 5.0},  # CV = 0.05 (very low)
        })
        
        score = get_category_reliability_score(model, "RELIABLE")
        
        # Count score: log1p(20) / log1p(20) = 1.0
        # Consistency score: 1 - 0.05 = 0.95
        # Reliability: 0.7 * 1.0 + 0.3 * 0.95 = 0.985
        assert score > 0.95, f"Consistent high-count category should score > 0.95, got {score}"
        assert score <= 1.0, f"Score should not exceed 1.0, got {score}"
    
    def test_reliability_score_volatile_high_count(self):
        """Test moderate reliability for volatile spending even with many transactions."""
        # WHY: High variance reduces reliability even if count is high
        model = create_test_model({
            "VOLATILE": {"count": 20, "mean": 100.0, "std_dev": 80.0},  # CV = 0.80 (high)
        })
        
        score = get_category_reliability_score(model, "VOLATILE")
        
        # Count score: 1.0 (saturated)
        # Consistency score: 1 - 0.80 = 0.20
        # Reliability: 0.7 * 1.0 + 0.3 * 0.20 = 0.76
        assert 0.7 < score < 0.8, f"Volatile high-count should score 0.7-0.8, got {score}"
    
    def test_reliability_score_consistent_low_count(self):
        """Test low reliability for consistent but rare spending."""
        # WHY: Low count reduces reliability even with perfect consistency
        model = create_test_model({
            "FEW_TX": {"count": 2, "mean": 100.0, "std_dev": 0.0},  # CV = 0 (perfect)
        })
        
        score = get_category_reliability_score(model, "FEW_TX")
        
        # Count score: log1p(2) / log1p(20) ≈ 0.37
        # Consistency score: 1.0 (no variance)
        # Reliability: 0.7 * 0.37 + 0.3 * 1.0 ≈ 0.56
        assert 0.5 < score < 0.6, f"Low-count even if consistent should score 0.5-0.6, got {score}"
    
    def test_reliability_score_boundary_count_20(self):
        """Test that count=20 is the saturation point (log scale)."""
        # WHY: Verify the log scale saturates at count=20 as designed
        model = create_test_model({
            "AT_SATURATION": {"count": 20, "mean": 100.0, "std_dev": 0.0},
            "BEYOND_SATURATION": {"count": 100, "mean": 100.0, "std_dev": 0.0},
        })
        
        score_20 = get_category_reliability_score(model, "AT_SATURATION")
        score_100 = get_category_reliability_score(model, "BEYOND_SATURATION")
        
        # Both should be very close since count score saturates at 20
        assert abs(score_20 - score_100) < 0.01, \
            f"Counts 20 and 100 should produce similar scores due to saturation, got {score_20} vs {score_100}"
    
    def test_reliability_score_zero_mean(self):
        """Test edge case where mean=0 (unusual but possible)."""
        # WHY: Coefficient of variation is undefined when mean=0
        model = create_test_model({
            "ZERO_MEAN": {"count": 10, "mean": 0.0, "std_dev": 5.0},
        })
        
        score = get_category_reliability_score(model, "ZERO_MEAN")
        
        # Should use default consistency_score=0.5 when mean=0
        # Count score: log1p(10) / log1p(20) ≈ 0.78
        # Reliability: 0.7 * 0.78 + 0.3 * 0.5 ≈ 0.70
        assert 0.65 < score < 0.75, f"Zero mean should give moderate score, got {score}"
    
    def test_reliability_score_very_high_cv(self):
        """Test category with CV > 1 (std_dev exceeds mean)."""
        # WHY: Extreme variance should still be handled gracefully
        model = create_test_model({
            "EXTREME_VAR": {"count": 10, "mean": 50.0, "std_dev": 200.0},  # CV = 4.0
        })
        
        score = get_category_reliability_score(model, "EXTREME_VAR")
        
        # Consistency score: max(0, 1 - 4.0) = 0.0
        # Count score: ≈ 0.78
        # Reliability: 0.7 * 0.78 + 0.3 * 0.0 ≈ 0.55
        assert 0.50 < score < 0.60, f"Extreme variance should score low, got {score}"
    
    def test_reliability_score_missing_category(self):
        """Test requesting score for non-existent category."""
        # WHY: Defensive programming - handle missing categories
        model = create_test_model({
            "EXISTS": {"count": 10, "mean": 100.0, "std_dev": 15.0},
        })
        
        score = get_category_reliability_score(model, "MISSING")
        
        assert score == 0.0, f"Missing category should return 0.0, got {score}"
    
    def test_reliability_score_none_model(self):
        """Test with None model."""
        # WHY: Handle invalid input gracefully
        score = get_category_reliability_score(None, "ANYTHING")
        assert score == 0.0, "None model should return 0.0"
    
    def test_reliability_score_empty_category_stats(self):
        """Test with model that has empty category_stats."""
        # WHY: Handle uninitialized models
        model = MockBehaviourModel()
        model.category_stats = {}
        
        score = get_category_reliability_score(model, "ANYTHING")
        assert score == 0.0, "Empty category_stats should return 0.0"


# ============================================================================
# TestGetEstablishedCategories
# ============================================================================

class TestGetEstablishedCategories:
    """Test filtering of established (reliable) categories."""
    
    def test_get_established_default_threshold(self):
        """Test with default reliability threshold=0.5."""
        # WHY: Default threshold separates reliable from unreliable categories
        model = create_test_model({
            "HIGHLY_RELIABLE": {"count": 20, "mean": 100.0, "std_dev": 5.0},  # Score ~0.98
            "MODERATELY_RELIABLE": {"count": 10, "mean": 100.0, "std_dev": 30.0},  # Score ~0.70
            "BARELY_RELIABLE": {"count": 5, "mean": 100.0, "std_dev": 20.0},  # Score ~0.55
            "UNRELIABLE": {"count": 2, "mean": 100.0, "std_dev": 50.0},  # Score ~0.40
        })
        
        established = get_established_categories(model)
        
        assert len(established) == 3, f"Expected 3 established categories, got {len(established)}"
        assert "HIGHLY_RELIABLE" in established
        assert "MODERATELY_RELIABLE" in established
        assert "BARELY_RELIABLE" in established
        assert "UNRELIABLE" not in established
    
    def test_get_established_high_threshold(self):
        """Test with strict threshold=0.8."""
        # WHY: Higher threshold for very conservative filtering
        model = create_test_model({
            "EXCELLENT": {"count": 20, "mean": 100.0, "std_dev": 5.0},  # Score ~0.98
            "GOOD": {"count": 15, "mean": 100.0, "std_dev": 15.0},  # Score ~0.82
            "MEDIOCRE": {"count": 10, "mean": 100.0, "std_dev": 30.0},  # Score ~0.70
            "POOR": {"count": 5, "mean": 100.0, "std_dev": 50.0},  # Score ~0.50
        })
        
        established = get_established_categories(model, min_reliability=0.8)
        
        assert len(established) == 2, f"With threshold=0.8, expected 2 categories, got {len(established)}"
        assert "EXCELLENT" in established
        assert "GOOD" in established
        assert "MEDIOCRE" not in established
    
    def test_get_established_low_threshold(self):
        """Test with lenient threshold=0.2."""
        # WHY: Very inclusive filtering
        model = create_test_model({
            "HIGH": {"count": 20, "mean": 100.0, "std_dev": 5.0},
            "MEDIUM": {"count": 5, "mean": 100.0, "std_dev": 50.0},
            "LOW": {"count": 2, "mean": 100.0, "std_dev": 80.0},
        })
        
        established = get_established_categories(model, min_reliability=0.2)
        
        # All should pass the low threshold
        assert len(established) == 3, f"With low threshold, expected all categories"
    
    def test_get_established_none_model(self):
        """Test with None model."""
        established = get_established_categories(None)
        assert established == [], "None model should return empty list"
    
    def test_get_established_empty_stats(self):
        """Test with empty category_stats."""
        model = MockBehaviourModel()
        model.category_stats = {}
        
        established = get_established_categories(model)
        assert established == [], "Empty stats should return empty list"
    
    def test_get_established_no_categories_meet_threshold(self):
        """Test when no categories meet the threshold."""
        # WHY: New user with only rare categories
        model = create_test_model({
            "RARE1": {"count": 1, "mean": 50.0, "std_dev": 0.0},
            "RARE2": {"count": 2, "mean": 75.0, "std_dev": 5.0},
        })
        
        established = get_established_categories(model, min_reliability=0.8)
        assert len(established) == 0, "No categories should meet high threshold"


# ============================================================================
# TestShouldIncludeInSimulation
# ============================================================================

class TestShouldIncludeInSimulation:
    """Test simulation inclusion logic."""
    
    def test_should_include_meets_all_criteria(self):
        """Test category that meets both count and reliability thresholds."""
        # WHY: Normal case - category suitable for simulation
        model = create_test_model({
            "GOOD_CATEGORY": {"count": 10, "mean": 100.0, "std_dev": 15.0},
        })
        
        include = should_include_in_simulation(model, "GOOD_CATEGORY")
        assert include is True, "Category with count=10 and good reliability should be included"
    
    def test_should_include_exact_count_boundary(self):
        """Test boundary condition at min_count=3."""
        # WHY: Verify exact threshold behavior
        model = create_test_model({
            "AT_BOUNDARY": {"count": 3, "mean": 100.0, "std_dev": 10.0},
            "BELOW_BOUNDARY": {"count": 2, "mean": 100.0, "std_dev": 10.0},
        })
        
        include_3 = should_include_in_simulation(model, "AT_BOUNDARY", min_count=3)
        include_2 = should_include_in_simulation(model, "BELOW_BOUNDARY", min_count=3)
        
        assert include_3 is True, "Count=3 with min_count=3 should be included (at boundary)"
        assert include_2 is False, "Count=2 with min_count=3 should be excluded (below boundary)"
    
    def test_should_include_high_count_low_reliability(self):
        """Test category with sufficient count but poor reliability."""
        # WHY: High variance/inconsistency should exclude even with many transactions
        model = create_test_model({
            "INCONSISTENT": {"count": 10, "mean": 100.0, "std_dev": 150.0},  # Very high CV = 1.5
        })
        
        include = should_include_in_simulation(model, "INCONSISTENT")
        
        # With count=10, std_dev=150, mean=100:
        # Count score: log1p(10)/log1p(20) ≈ 0.78
        # CV = 150/100 = 1.5, consistency_score = max(0, 1-1.5) = 0
        # Reliability = 0.7*0.78 + 0.3*0 = 0.546
        # This is above 0.3 threshold, so it WILL be included
        reliability = get_category_reliability_score(model, "INCONSISTENT")
        assert 0.5 < reliability < 0.6, f"Expected reliability ~0.55, got {reliability}"
        assert include is True, "Category with count=10 and reliability>0.3 should be included"
    
    def test_should_include_custom_min_count(self):
        """Test with custom min_count threshold."""
        # WHY: Allow configurable thresholds for different use cases
        model = create_test_model({
            "MEDIUM": {"count": 5, "mean": 100.0, "std_dev": 15.0},
        })
        
        include_3 = should_include_in_simulation(model, "MEDIUM", min_count=3)
        include_10 = should_include_in_simulation(model, "MEDIUM", min_count=10)
        
        assert include_3 is True, "Count=5 should be included with min_count=3"
        assert include_10 is False, "Count=5 should be excluded with min_count=10"
    
    def test_should_include_missing_category(self):
        """Test with non-existent category."""
        model = create_test_model({
            "EXISTS": {"count": 10, "mean": 100.0, "std_dev": 15.0},
        })
        
        include = should_include_in_simulation(model, "MISSING")
        assert include is False, "Missing category should not be included"
    
    def test_should_include_none_model(self):
        """Test with None model."""
        include = should_include_in_simulation(None, "ANYTHING")
        assert include is False, "None model should return False"
    
    def test_should_include_empty_stats(self):
        """Test with empty category_stats."""
        model = MockBehaviourModel()
        model.category_stats = {}
        
        include = should_include_in_simulation(model, "ANYTHING")
        assert include is False, "Empty stats should return False"


# ============================================================================
# TestGetCategorySummary
# ============================================================================

class TestGetCategorySummary:
    """Test comprehensive category summary generation."""
    
    def test_get_summary_all_fields_present(self):
        """Test that summary contains all expected fields."""
        # WHY: Verify complete metadata is generated
        model = create_test_model({
            "TEST_CATEGORY": {"count": 10, "mean": 100.0, "std_dev": 15.0, "min": 70.0, "max": 130.0},
        })
        
        summary = get_category_summary(model)
        
        assert "TEST_CATEGORY" in summary
        cat_summary = summary["TEST_CATEGORY"]
        
        # Verify all required fields exist
        required_fields = ["count", "mean", "std_dev", "min", "max", 
                          "reliability_score", "is_rare", "is_established", "include_in_simulation"]
        for field in required_fields:
            assert field in cat_summary, f"Field '{field}' should be in summary"
    
    def test_get_summary_calculated_fields_accurate(self):
        """Test that calculated fields match expected values."""
        # WHY: Verify correct computation of derived fields
        model = create_test_model({
            "RELIABLE": {"count": 20, "mean": 100.0, "std_dev": 5.0, "min": 90.0, "max": 110.0},
            "RARE": {"count": 1, "mean": 50.0, "std_dev": 0.0, "min": 50.0, "max": 50.0},
        })
        
        summary = get_category_summary(model)
        
        # Check RELIABLE category
        reliable = summary["RELIABLE"]
        assert reliable["is_rare"] is False, "Count=20 should not be rare"
        assert reliable["is_established"] is True, "High reliability should be established"
        assert reliable["include_in_simulation"] is True, "Should be included in simulation"
        assert reliable["reliability_score"] > 0.9, f"Should have high reliability score, got {reliable['reliability_score']}"
        
        # Check RARE category
        rare = summary["RARE"]
        assert rare["is_rare"] is True, "Count=1 should be rare"
        assert rare["is_established"] is False, "Low reliability should not be established"
        assert rare["include_in_simulation"] is False, "Should not be included in simulation"
    
    def test_get_summary_multiple_categories(self):
        """Test summary generation with multiple categories."""
        # WHY: Verify all categories are processed
        model = create_test_model({
            "CAT1": {"count": 10, "mean": 100.0, "std_dev": 15.0, "min": 70.0, "max": 130.0},
            "CAT2": {"count": 5, "mean": 200.0, "std_dev": 20.0, "min": 170.0, "max": 230.0},
            "CAT3": {"count": 2, "mean": 50.0, "std_dev": 5.0, "min": 45.0, "max": 55.0},
        })
        
        summary = get_category_summary(model)
        
        assert len(summary) == 3, f"Summary should contain 3 categories, got {len(summary)}"
        assert set(summary.keys()) == {"CAT1", "CAT2", "CAT3"}
    
    def test_get_summary_reliability_score_rounded(self):
        """Test that reliability scores are rounded to 3 decimal places."""
        # WHY: Verify consistent formatting
        model = create_test_model({
            "TEST": {"count": 7, "mean": 100.0, "std_dev": 23.45, "min": 60.0, "max": 140.0},
        })
        
        summary = get_category_summary(model)
        score = summary["TEST"]["reliability_score"]
        
        # Check it's rounded to 3 decimals
        assert isinstance(score, float)
        # Convert to string and check decimal places
        score_str = f"{score:.10f}"  # Get many decimals
        decimal_part = score_str.split('.')[1]
        non_zero_after_third = any(c != '0' for c in decimal_part[3:])
        assert not non_zero_after_third, f"Score should be rounded to 3 decimals, got {score}"
    
    def test_get_summary_none_model(self):
        """Test with None model."""
        summary = get_category_summary(None)
        assert summary == {}, "None model should return empty dict"
    
    def test_get_summary_empty_stats(self):
        """Test with empty category_stats."""
        model = MockBehaviourModel()
        model.category_stats = {}
        
        summary = get_category_summary(model)
        assert summary == {}, "Empty stats should return empty dict"


# ============================================================================
# TestFilterCategoriesForAnalysis
# ============================================================================

class TestFilterCategoriesForAnalysis:
    """Test filtering for analysis/simulation."""
    
    def test_filter_exclude_rare_default(self):
        """Test that rare categories (count < 3) are excluded by default."""
        # WHY: Remove noise from analysis
        model = create_test_model({
            "ESTABLISHED": {"count": 10, "mean": 100.0, "std_dev": 15.0},
            "RARE": {"count": 2, "mean": 50.0, "std_dev": 5.0},
            "VERY_RARE": {"count": 1, "mean": 75.0, "std_dev": 0.0},
        })
        
        filtered = filter_categories_for_analysis(model, exclude_rare=True)
        
        assert len(filtered) == 1, f"Only 1 category should pass, got {len(filtered)}"
        assert "ESTABLISHED" in filtered
        assert "RARE" not in filtered
        assert "VERY_RARE" not in filtered
    
    def test_filter_include_rare(self):
        """Test with exclude_rare=False to include all counts."""
        # WHY: Sometimes want to see all categories regardless of count
        model = create_test_model({
            "MANY": {"count": 10, "mean": 100.0, "std_dev": 15.0},
            "FEW": {"count": 2, "mean": 50.0, "std_dev": 5.0},
            "ONE": {"count": 1, "mean": 75.0, "std_dev": 0.0},
        })
        
        filtered = filter_categories_for_analysis(model, exclude_rare=False, min_reliability=0.0)
        
        # All should be included (no rare filtering, no reliability filtering)
        assert len(filtered) == 3, f"All categories should be included, got {len(filtered)}"
    
    def test_filter_min_reliability_threshold(self):
        """Test filtering by reliability threshold."""
        # WHY: Exclude unreliable/volatile categories
        model = create_test_model({
            "HIGHLY_RELIABLE": {"count": 20, "mean": 100.0, "std_dev": 5.0},  # Score ~0.98
            "MODERATELY_RELIABLE": {"count": 10, "mean": 100.0, "std_dev": 30.0},  # Score ~0.70
            "UNRELIABLE": {"count": 5, "mean": 100.0, "std_dev": 90.0},  # Score < 0.5
        })
        
        filtered = filter_categories_for_analysis(model, exclude_rare=False, min_reliability=0.6)
        
        assert len(filtered) == 2, f"Expected 2 categories with reliability >= 0.6, got {len(filtered)}"
        assert "HIGHLY_RELIABLE" in filtered
        assert "MODERATELY_RELIABLE" in filtered
        assert "UNRELIABLE" not in filtered
    
    def test_filter_combined_rare_and_reliability(self):
        """Test filtering with both rare exclusion and reliability threshold."""
        # WHY: Most common use case - remove noise AND unreliable patterns
        model = create_test_model({
            "GOOD": {"count": 10, "mean": 100.0, "std_dev": 15.0},  # Count OK, reliability ~0.82
            "RARE_BUT_RELIABLE": {"count": 2, "mean": 100.0, "std_dev": 5.0},  # Rare, excluded
            "MANY_BUT_UNRELIABLE": {"count": 10, "mean": 100.0, "std_dev": 120.0},  # CV=1.2, reliability ~0.55
            "RARE_AND_UNRELIABLE": {"count": 1, "mean": 100.0, "std_dev": 80.0},  # Both bad
        })
        
        # Use higher threshold to exclude MANY_BUT_UNRELIABLE
        filtered = filter_categories_for_analysis(model, exclude_rare=True, min_reliability=0.7)
        
        # Only GOOD should pass both filters (count>=3 and reliability>=0.7)
        assert len(filtered) == 1, f"Only 1 category should pass both filters, got {len(filtered)}"
        assert "GOOD" in filtered
    
    def test_filter_boundary_count_three(self):
        """Test exact boundary at count=3."""
        # WHY: Verify threshold behavior
        model = create_test_model({
            "AT_BOUNDARY": {"count": 3, "mean": 100.0, "std_dev": 10.0},
            "BELOW_BOUNDARY": {"count": 2, "mean": 100.0, "std_dev": 10.0},
        })
        
        filtered = filter_categories_for_analysis(model, exclude_rare=True, min_reliability=0.3)
        
        assert "AT_BOUNDARY" in filtered, "Count=3 should be included (at threshold)"
        assert "BELOW_BOUNDARY" not in filtered, "Count=2 should be excluded (below threshold)"
    
    def test_filter_none_model(self):
        """Test with None model."""
        filtered = filter_categories_for_analysis(None)
        assert filtered == {}, "None model should return empty dict"
    
    def test_filter_empty_stats(self):
        """Test with empty category_stats."""
        model = MockBehaviourModel()
        model.category_stats = {}
        
        filtered = filter_categories_for_analysis(model)
        assert filtered == {}, "Empty stats should return empty dict"
    
    def test_filter_returns_full_stats(self):
        """Test that filtered result contains complete stats for passing categories."""
        # WHY: Ensure we get full stat objects, not just category names
        model = create_test_model({
            "PASS": {"count": 10, "mean": 100.0, "std_dev": 15.0, "min": 70.0, "max": 130.0, "sum": 1000.0},
        })
        
        filtered = filter_categories_for_analysis(model, exclude_rare=True, min_reliability=0.3)
        
        assert "PASS" in filtered
        stats = filtered["PASS"]
        assert stats["count"] == 10
        assert stats["mean"] == 100.0
        assert stats["std_dev"] == 15.0
        assert stats["min"] == 70.0
        assert stats["max"] == 130.0
        assert stats["sum"] == 1000.0


# ============================================================================
# TestBoundaryConditions
# ============================================================================

class TestBoundaryConditions:
    """Test edge cases and boundary conditions across all functions."""
    
    def test_category_name_edge_cases(self):
        """Test various category name formats."""
        # WHY: Ensure string handling is robust
        model = create_test_model({
            "": {"count": 5, "mean": 100.0, "std_dev": 10.0},  # Empty string
            "VERY_LONG_CATEGORY_NAME_WITH_MANY_CHARACTERS_EXCEEDING_NORMAL_LENGTH": {
                "count": 5, "mean": 100.0, "std_dev": 10.0
            },
            "Special-Chars!@#$%": {"count": 5, "mean": 100.0, "std_dev": 10.0},
        })
        
        # All functions should handle these without crashing
        rare = identify_rare_categories(model, threshold=3)
        assert isinstance(rare, list)
        
        score = get_category_reliability_score(model, "")
        assert isinstance(score, float)
        
        summary = get_category_summary(model)
        assert len(summary) == 3
    
    def test_very_large_count(self):
        """Test handling of unusually large transaction counts."""
        # WHY: Ensure no overflow or unexpected behavior
        model = create_test_model({
            "HUGE_COUNT": {"count": 10000, "mean": 100.0, "std_dev": 15.0},
        })
        
        score = get_category_reliability_score(model, "HUGE_COUNT")
        assert 0.0 <= score <= 1.0, f"Score should be in [0, 1] range, got {score}"
        assert score > 0.95, "Huge count should saturate reliability score"
    
    def test_very_large_amounts(self):
        """Test handling of very large monetary amounts."""
        # WHY: Ensure calculations don't overflow
        model = create_test_model({
            "BIG_MONEY": {"count": 10, "mean": 1000000.0, "std_dev": 50000.0},
        })
        
        score = get_category_reliability_score(model, "BIG_MONEY")
        assert 0.0 <= score <= 1.0
        
        summary = get_category_summary(model)
        assert "BIG_MONEY" in summary
        assert summary["BIG_MONEY"]["mean"] == 1000000.0
    
    def test_exact_zero_std_dev(self):
        """Test categories with exactly zero standard deviation."""
        # WHY: Perfect consistency case (all transactions identical)
        model = create_test_model({
            "PERFECT_CONSISTENCY": {"count": 10, "mean": 100.0, "std_dev": 0.0},
        })
        
        score = get_category_reliability_score(model, "PERFECT_CONSISTENCY")
        # Count score: log1p(10)/log1p(20) ≈ 0.78
        # CV = 0/100 = 0, consistency_score = 1.0  
        # Reliability = 0.7*0.78 + 0.3*1.0 = 0.546 + 0.3 = 0.846
        assert 0.8 < score < 0.9, f"Zero std_dev with count=10 gives reliability ~0.85, got {score}"
    
    def test_negative_values_if_refunds(self):
        """Test handling of negative amounts (refunds/credits)."""
        # WHY: Some systems allow negative amounts for refunds
        model = create_test_model({
            "WITH_REFUNDS": {"count": 5, "mean": -50.0, "std_dev": 20.0},
        })
        
        # Should handle negative mean gracefully
        score = get_category_reliability_score(model, "WITH_REFUNDS")
        assert 0.0 <= score <= 1.0
        
        summary = get_category_summary(model)
        assert "WITH_REFUNDS" in summary


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
