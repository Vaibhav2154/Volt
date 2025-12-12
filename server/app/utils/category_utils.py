"""
Category management utilities for behavior tracking.

Handles:
- Rare/one-off category detection
- Category consolidation recommendations
- Noise filtering
"""
from typing import Dict, List, Tuple
from app.models.behaviour import BehaviourModel


def identify_rare_categories(model: BehaviourModel, threshold: int = 3) -> List[str]:
    """
    Identify categories with very few transactions (potential noise).
    
    Args:
        model: BehaviourModel instance
        threshold: Minimum transaction count to be considered "established"
        
    Returns:
        List of category names that are rare/infrequent
    """
    if not model or not model.category_stats:
        return []
    
    rare_categories = []
    for category, stats in model.category_stats.items():
        if stats.get("count", 0) < threshold:
            rare_categories.append(category)
    
    return rare_categories


def get_category_reliability_score(model: BehaviourModel, category: str) -> float:
    """
    Calculate reliability score for a category (0-1).
    
    Higher score = more reliable/established category
    Lower score = rare/noisy category
    
    Factors:
    - Transaction count (more = better)
    - Consistency (lower variance relative to mean = better)
    - Recency (has recent transactions = better)
    
    Args:
        model: BehaviourModel instance
        category: Category name
        
    Returns:
        Reliability score between 0.0 and 1.0
    """
    if not model or not model.category_stats or category not in model.category_stats:
        return 0.0
    
    stats = model.category_stats[category]
    count = stats.get("count", 0)
    mean = stats.get("mean", 0)
    std_dev = stats.get("std_dev", 0)
    
    # Count score: 0-1 based on log scale (saturates at ~20 transactions)
    import math
    count_score = min(1.0, math.log1p(count) / math.log1p(20))
    
    # Consistency score: 0-1 based on coefficient of variation
    # Lower CV = more consistent = higher score
    if mean > 0:
        cv = std_dev / mean
        consistency_score = max(0.0, 1.0 - min(1.0, cv))
    else:
        consistency_score = 0.5
    
    # Weight: count matters more than consistency for reliability
    reliability = 0.7 * count_score + 0.3 * consistency_score
    
    return reliability


def get_established_categories(model: BehaviourModel, min_reliability: float = 0.5) -> List[str]:
    """
    Get list of established (reliable) categories.
    
    Args:
        model: BehaviourModel instance
        min_reliability: Minimum reliability score (0-1)
        
    Returns:
        List of category names that are established
    """
    if not model or not model.category_stats:
        return []
    
    established = []
    for category in model.category_stats.keys():
        if get_category_reliability_score(model, category) >= min_reliability:
            established.append(category)
    
    return established


def should_include_in_simulation(model: BehaviourModel, category: str, min_count: int = 3) -> bool:
    """
    Determine if a category should be included in simulations/predictions.
    
    Args:
        model: BehaviourModel instance
        category: Category name
        min_count: Minimum transaction count to include
        
    Returns:
        True if category should be included in simulations
    """
    if not model or not model.category_stats or category not in model.category_stats:
        return False
    
    stats = model.category_stats[category]
    count = stats.get("count", 0)
    
    # Must have minimum transaction count
    if count < min_count:
        return False
    
    # Must have reasonable reliability
    reliability = get_category_reliability_score(model, category)
    if reliability < 0.3:
        return False
    
    return True


def get_category_summary(model: BehaviourModel) -> Dict[str, Dict]:
    """
    Get comprehensive summary of all categories with metadata.
    
    Returns:
        Dict mapping category name to summary info including:
        - count, mean, std_dev (from stats)
        - reliability_score
        - is_rare
        - is_established
        - include_in_simulation
    """
    if not model or not model.category_stats:
        return {}
    
    summary = {}
    for category, stats in model.category_stats.items():
        reliability = get_category_reliability_score(model, category)
        is_rare = stats.get("count", 0) < 3
        is_established = reliability >= 0.5
        include_sim = should_include_in_simulation(model, category)
        
        summary[category] = {
            "count": stats.get("count", 0),
            "mean": stats.get("mean", 0),
            "std_dev": stats.get("std_dev", 0),
            "min": stats.get("min", 0),
            "max": stats.get("max", 0),
            "reliability_score": round(reliability, 3),
            "is_rare": is_rare,
            "is_established": is_established,
            "include_in_simulation": include_sim,
        }
    
    return summary


def filter_categories_for_analysis(
    model: BehaviourModel,
    exclude_rare: bool = True,
    min_reliability: float = 0.3
) -> Dict[str, Dict]:
    """
    Get filtered category stats suitable for analysis/simulation.
    
    Removes noise and rare categories that would skew results.
    
    Args:
        model: BehaviourModel instance
        exclude_rare: If True, exclude categories with < 3 transactions
        min_reliability: Minimum reliability score to include
        
    Returns:
        Filtered dict of category_name -> stats
    """
    if not model or not model.category_stats:
        return {}
    
    filtered = {}
    for category, stats in model.category_stats.items():
        # Check rare
        if exclude_rare and stats.get("count", 0) < 3:
            continue
        
        # Check reliability
        if get_category_reliability_score(model, category) < min_reliability:
            continue
        
        filtered[category] = stats
    
    return filtered
