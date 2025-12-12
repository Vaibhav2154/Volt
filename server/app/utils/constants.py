
# Essential categories (hard to reduce)
ESSENTIAL_CATEGORIES = {
    "GROCERIES", "UTILITIES", "RENT", "HEALTHCARE", "TRANSPORTATION", "HOUSING"
}

# Discretionary categories (easier to reduce)
DISCRETIONARY_CATEGORIES = {
    "ENTERTAINMENT", "DINING", "SHOPPING", "TRAVEL"
}

# Freelancer/Gig worker specific categories
FREELANCER_CATEGORIES = {
    "BUSINESS_EXPENSE",      # Equipment, software, coworking
    "TAX_SAVINGS",           # Quarterly tax payments
    "EMERGENCY_FUND",        # Critical for variable income
    "PROFESSIONAL_DEVELOPMENT",  # Courses, certifications
    "CLIENT_ACQUISITION"     # Marketing, networking
}

# Flexible/Variable categories (can adjust based on income)
FLEXIBLE_CATEGORIES = {
    "SAVINGS", "INVESTMENTS", "DEBT_PAYMENT", "SUBSCRIPTIONS"
}

# All valid categories
ALL_CATEGORIES = (ESSENTIAL_CATEGORIES | DISCRETIONARY_CATEGORIES | 
                  FREELANCER_CATEGORIES | FLEXIBLE_CATEGORIES | {"OTHER", "UNCATEGORIZED"})

# Time decay for older transactions
DECAY_FACTOR = 0.98

# Elasticity base values (how easily spending can be reduced)
ELASTICITY_CONFIG = {
    # Essential - low elasticity (hard to cut)
    "GROCERIES": 0.15,
    "UTILITIES": 0.10,
    "RENT": 0.05,
    "HOUSING": 0.05,
    "HEALTHCARE": 0.12,
    "TRANSPORTATION": 0.25,
    
    # Discretionary - high elasticity (easy to cut)
    "ENTERTAINMENT": 0.75,
    "DINING": 0.70,
    "SHOPPING": 0.65,
    "TRAVEL": 0.80,
    
    # Freelancer-specific - moderate elasticity (should protect some)
    "BUSINESS_EXPENSE": 0.30,      # Need tools to work
    "TAX_SAVINGS": 0.05,            # Must pay taxes
    "EMERGENCY_FUND": 0.20,         # Critical but can pause temporarily
    "PROFESSIONAL_DEVELOPMENT": 0.50, # Important but can delay
    "CLIENT_ACQUISITION": 0.40,     # Important for future income
    
    # Flexible - very high elasticity (highly adjustable)
    "SAVINGS": 0.90,
    "INVESTMENTS": 0.85,
    "DEBT_PAYMENT": 0.15,           # Minimum payments required
    "SUBSCRIPTIONS": 0.80,
    
    # Default
    "OTHER": 0.40,
    "UNCATEGORIZED": 0.40
}

# Merchant keywords for rule-based categorization (fallback)
MERCHANT_KEYWORDS = {
    "GROCERIES": ["grocery", "supermarket", "food mart", "fresh", "bigbasket", "grofers", "walmart", "costco", "trader joe"],
    "UTILITIES": ["electric", "water", "gas", "internet", "broadband", "airtel", "jio", "verizon", "comcast"],
    "RENT": ["rent", "housing", "apartment", "lease"],
    "HOUSING": ["rent", "mortgage", "housing", "apartment", "lease", "property"],
    "HEALTHCARE": ["hospital", "clinic", "pharmacy", "medical", "apollo", "practo", "cvs", "walgreens"],
    "TRANSPORTATION": ["uber", "ola", "metro", "petrol", "fuel", "rapido", "lyft", "gas station", "shell", "chevron"],
    "DINING": ["restaurant", "cafe", "swiggy", "zomato", "dining", "dominos", "mcdonald", "chipotle", "starbucks"],
    "SHOPPING": ["mall", "store", "shop", "amazon", "flipkart", "myntra", "target", "etsy"],
    "ENTERTAINMENT": ["movie", "netflix", "spotify", "game", "hotstar", "prime", "hulu", "disney"],
    "TRAVEL": ["hotel", "flight", "travel", "booking", "makemytrip", "goibibo", "airbnb"],
    
    # Freelancer-specific
    "BUSINESS_EXPENSE": ["adobe", "office", "slack", "zoom", "github", "aws", "domain", "hosting", "coworking", "wework"],
    "TAX_SAVINGS": ["irs", "tax", "quarterly", "estimated tax"],
    "EMERGENCY_FUND": ["emergency", "contingency", "rainy day"],
    "PROFESSIONAL_DEVELOPMENT": ["udemy", "coursera", "linkedin learning", "pluralsight", "conference", "workshop"],
    "CLIENT_ACQUISITION": ["linkedin", "upwork", "fiverr", "ads", "marketing"],
    
    # Flexible
    "SAVINGS": ["savings", "deposit", "transfer to savings"],
    "INVESTMENTS": ["vanguard", "fidelity", "robinhood", "investment", "401k", "ira", "crypto"],
    "SUBSCRIPTIONS": ["subscription", "monthly", "premium"],
}