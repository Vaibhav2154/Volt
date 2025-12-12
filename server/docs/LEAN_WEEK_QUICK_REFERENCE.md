# Lean Week Predictor - Quick Reference

## 🚀 Quick Start

### Test the Implementation
```bash
cd /home/yashas/Work/projects/Volt/server
source venv/bin/activate
python test_lean_week_comprehensive.py
```

### Start the Server
```bash
cd /home/yashas/Work/projects/Volt/server
source venv/bin/activate
python run.py
```

### Access API Documentation
```
http://localhost:8000/docs
```
Look for the "Lean Week Predictor" section

---

## 📍 API Endpoints

### 1. Complete Analysis
```bash
GET /lean-week/analysis?current_balance=5000
```
Returns: Risk assessment + history + forecast + recommendations

### 2. Cash Flow Forecast Only
```bash
GET /lean-week/forecast?periods=6&current_balance=5000
```
Returns: 6-month forecast with best/likely/worst scenarios

### 3. Savings Recommendations Only
```bash
GET /lean-week/smoothing-recommendations?target_months=6
```
Returns: How much to save, emergency fund targets

---

## 📦 Files Added

```
server/
├── app/
│   ├── services/
│   │   └── lean_week_predictor.py          # Core service (600+ lines)
│   ├── schemas/
│   │   └── lean_week_schemas.py            # API response models
│   └── routers/
│       └── lean_week_router.py             # API endpoints
├── test_lean_week_comprehensive.py          # Test suite
└── LEAN_WEEK_PREDICTOR_README.md           # Full documentation
```

---

## 🔑 Key Features

| Feature | What It Does | Benefit |
|---------|--------------|---------|
| **Lean Period Detection** | Identifies bottom 25% of cash flow periods | Know when trouble hits |
| **Cash Flow Forecast** | Predicts 3-12 months ahead | Plan for future |
| **Income Smoothing** | Calculates savings rate needed | Build emergency fund |
| **Risk Assessment** | Scores risk 0-10+ (MINIMAL → CRITICAL) | Prioritize actions |
| **Pattern Detection** | Finds month-end, seasonal patterns | Anticipate challenges |

---

## 💡 Example Response

```json
{
  "summary": {
    "risk_level": "MODERATE",
    "risk_message": "Some financial challenges - proactive management recommended"
  },
  "cash_flow_forecast": {
    "forecasts": [
      {
        "period": 1,
        "net_cash_flow": {"best": 3596, "likely": 2027, "worst": -2132},
        "is_lean_period": true
      }
    ],
    "confidence": 0.38
  },
  "income_smoothing": {
    "recommended_save_rate": 0.35,
    "monthly_save_amount": 1120,
    "months_to_target": 2.8
  }
}
```

---

## 🎯 Use Cases

### For Freelancers
✓ Know which months will be lean  
✓ Calculate exact savings needed  
✓ Get warned before cash runs out  

### For Gig Workers
✓ Smooth irregular income  
✓ Build emergency fund systematically  
✓ Reduce financial stress  

### For Contractors
✓ Forecast project gaps  
✓ Plan for slow seasons  
✓ Optimize payment timing  

---

## 🔧 How It Works (Simplified)

1. **Analyze History**
   - Groups transactions by month
   - Calculates income - expenses = net flow
   - Identifies lean periods (negative or low net flow)

2. **Forecast Future**
   - Uses exponential smoothing on income history
   - Generates 3 scenarios (best/likely/worst)
   - Projects running balance

3. **Recommend Actions**
   - Calculates emergency fund target (3-6 months expenses)
   - Determines savings rate for good months
   - Provides specific action items

4. **Assess Risk**
   - Scores based on: lean frequency, warnings, fund coverage, volatility
   - Categorizes: MINIMAL → LOW → MODERATE → HIGH → CRITICAL
   - Flags immediate action needed

---

## 📊 Metrics Explained

### Lean Frequency
- `0.25` = 25% of months are lean
- `0.50` = 50% of months are lean (concerning)
- `>0.40` = High frequency, build larger emergency fund

### Income Volatility
- `<0.2` = Stable (consistent monthly income)
- `0.2-0.4` = Moderate (some variation)
- `>0.4` = High (freelancer/gig typical)

### Confidence Score
- `>0.8` = High confidence (reliable forecast)
- `0.5-0.8` = Moderate confidence
- `<0.5` = Low confidence (insufficient data or high volatility)

---

## ⚠️ Requirements

**Minimum Data:**
- 2 months of transaction history
- At least 10 transactions

**Optimal Data:**
- 6+ months of history
- Regular transaction recording
- Both income and expense transactions

---

## 🧪 Testing

### Quick Test
```bash
python test_lean_week_comprehensive.py
```

### Expected Output
```
✓ Testing with User: test@simulation.com
✓ Found 84 transactions
✓ Retrieved 4 months of data
✓ Lean Frequency: 50.0%
🎯 RISK LEVEL: CRITICAL
✅ All tests completed successfully!
```

---

## 🔗 Integration Examples

### cURL
```bash
# Get complete analysis
curl -X GET "http://localhost:8000/lean-week/analysis?current_balance=5000" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Python
```python
import requests

response = requests.get(
    "http://localhost:8000/lean-week/analysis",
    headers={"Authorization": f"Bearer {token}"},
    params={"current_balance": 5000}
)
data = response.json()
print(f"Risk: {data['summary']['risk_level']}")
```

### JavaScript/TypeScript
```javascript
const response = await fetch(
  'http://localhost:8000/lean-week/analysis?current_balance=5000',
  { headers: { 'Authorization': `Bearer ${token}` } }
);
const data = await response.json();
console.log(`Risk: ${data.summary.risk_level}`);
```

---

## 📖 Full Documentation

See **LEAN_WEEK_PREDICTOR_README.md** for:
- Detailed algorithm explanations
- Complete API documentation
- Frontend integration guides
- Troubleshooting tips
- Advanced use cases

---

## ✅ Checklist

- [x] Service created (`lean_week_predictor.py`)
- [x] Schemas defined (`lean_week_schemas.py`)
- [x] Router implemented (`lean_week_router.py`)
- [x] Registered in main.py
- [x] Tested with real data
- [x] Documentation complete
- [x] Ready for production

---

## 🎉 You're All Set!

The Lean Week Predictor is **fully implemented and tested**. 

**Next Steps:**
1. Start your server: `python run.py`
2. Test an endpoint: `GET /lean-week/analysis`
3. Integrate into your mobile app
4. Help users avoid financial stress!

---

*Quick Reference v1.0 - December 12, 2025*
