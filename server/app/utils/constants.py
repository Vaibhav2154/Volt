
ESSENTIAL_CATEGORIES = {
    "GROCERIES", "UTILITIES", "RENT", "HEALTHCARE", "TRANSPORTATION"
}

DISCRETIONARY_CATEGORIES = {
    "ENTERTAINMENT", "DINING", "SHOPPING", "TRAVEL"
}

# All valid categories
ALL_CATEGORIES = ESSENTIAL_CATEGORIES | DISCRETIONARY_CATEGORIES | {"OTHER"}

# Time decay for older transactions
DECAY_FACTOR = 0.98

# Elasticity base values
ELASTICITY_CONFIG = {
    "GROCERIES": 0.15,
    "UTILITIES": 0.10,
    "RENT": 0.05,
    "HEALTHCARE": 0.12,
    "TRANSPORTATION": 0.25,
    "ENTERTAINMENT": 0.75,
    "DINING": 0.70,
    "SHOPPING": 0.65,
    "TRAVEL": 0.80,
    "OTHER": 0.40
}

# Merchant keywords for rule-based categorization (fallback)
MERCHANT_KEYWORDS = {
    "GROCERIES": ["grocery", "supermarket", "food mart", "fresh", "bigbasket", "grofers"],
    "UTILITIES": ["electric", "water", "gas", "internet", "broadband", "airtel", "jio"],
    "RENT": ["rent", "housing", "apartment", "lease"],
    "HEALTHCARE": ["hospital", "clinic", "pharmacy", "medical", "apollo", "practo"],
    "TRANSPORTATION": ["uber", "ola", "metro", "petrol", "fuel", "rapido"],
    "DINING": ["restaurant", "cafe", "swiggy", "zomato", "dining", "dominos", "mcdonald"],
    "SHOPPING": ["mall", "store", "shop", "amazon", "flipkart", "myntra"],
    "ENTERTAINMENT": ["movie", "netflix", "spotify", "game", "hotstar", "prime"],
    "TRAVEL": ["hotel", "flight", "travel", "booking", "makemytrip", "goibibo"]
}