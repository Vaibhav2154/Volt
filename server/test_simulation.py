"""
Quick test script for simulation engine.
Run with: python test_simulation.py
"""

import sys
import os
import asyncio
from datetime import datetime, timedelta
from decimal import Decimal

# Add server to path
sys.path.insert(0, os.path.dirname(__file__))

from app.database import SessionLocal
from app.models.user import User
from app.models.transactions import Transaction
from app.models.behaviour import BehaviourModel
from app.services.behavior_engine import BehaviorEngine
from app.services.categorization import CategorizationService
from app.services.simulation import SimulationService


def create_test_user(db):
    """Create or get test user"""
    user = db.query(User).filter_by(email="test@simulation.com").first()
    if not user:
        user = User(
            email="test@simulation.com",
            name="Test User",
            phone_number="+1234567890",
            hashed_password="hashed_dummy_password"
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    return user


def seed_test_transactions(db, user_id: int, days: int = 30):
    """Create realistic test transactions for a freelancer"""
    
    # Delete existing test transactions
    db.query(Transaction).filter_by(user_id=user_id).delete()
    db.commit()
    
    base_date = datetime.utcnow()
    transactions = []
    
    # Income (variable - freelancer style)
    income_data = [
        (5, 2500.00, "Client A Payment", "credit"),
        (12, 1800.00, "Client B Payment", "credit"),
        (20, 3200.00, "Client C Payment", "credit"),
        (28, 900.00, "Small Project", "credit"),
    ]
    
    # Essential expenses
    expenses_data = [
        # Rent/Housing
        (92, 12000.00, "Rent Payment", "debit", "HOUSING"),
        
        (1, 45.20, "Walmart", "debit", "GROCERIES"),
    (2, 63.10, "Costco", "debit", "GROCERIES"),
    (3, 23.55, "Local Market", "debit", "GROCERIES"),
    (4, 89.99, "Whole Foods", "debit", "GROCERIES"),
    (5, 15.75, "Trader Joes", "debit", "GROCERIES"),
    (6, 49.30, "Aldi", "debit", "GROCERIES"),
    (7, 34.10, "Kroger", "debit", "GROCERIES"),
    (8, 27.45, "Sprouts", "debit", "GROCERIES"),
    (9, 18.90, "Farmer's Market", "debit", "GROCERIES"),
    (10, 95.00, "Costco Bulk", "debit", "GROCERIES"),

    # 11–20: Dining
    (11, 14.99, "Chipotle", "debit", "DINING"),
    (12, 32.50, "Sushi Bar", "debit", "DINING"),
    (13, 9.80, "Starbucks", "debit", "DINING"),
    (14, 22.30, "Pizza Place", "debit", "DINING"),
    (15, 65.00, "Fancy Restaurant", "debit", "DINING"),
    (16, 19.75, "Taco Truck", "debit", "DINING"),
    (17, 25.40, "Thai Restaurant", "debit", "DINING"),
    (18, 11.50, "Coffee Shop", "debit", "DINING"),
    (19, 44.60, "Seafood Grill", "debit", "DINING"),
    (20, 13.20, "Burger Joint", "debit", "DINING"),

    # 21–30: Transport
    (21, 40.00, "Gas Station", "debit", "TRANSPORT"),
    (22, 55.00, "Shell Gas", "debit", "TRANSPORT"),
    (23, 12.50, "Uber", "debit", "TRANSPORT"),
    (24, 3.00, "Metro Ticket", "debit", "TRANSPORT"),
    (25, 29.90, "Lyft", "debit", "TRANSPORT"),
    (26, 62.30, "Chevron", "debit", "TRANSPORT"),
    (27, 15.00, "Parking Garage", "debit", "TRANSPORT"),
    (28, 7.50, "Bus Pass", "debit", "TRANSPORT"),
    (29, 10.00, "Train Fare", "debit", "TRANSPORT"),
    (30, 48.20, "EV Charging", "debit", "TRANSPORT"),

    # 31–40: Entertainment
    (31, 15.99, "Netflix", "debit", "ENTERTAINMENT"),
    (32, 9.99, "Spotify", "debit", "ENTERTAINMENT"),
    (33, 24.00, "Movie Theater", "debit", "ENTERTAINMENT"),
    (34, 59.99, "Concert Tickets", "debit", "ENTERTAINMENT"),
    (35, 12.99, "YouTube Premium", "debit", "ENTERTAINMENT"),
    (36, 45.00, "Amusement Park", "debit", "ENTERTAINMENT"),
    (37, 4.99, "Mobile Game", "debit", "ENTERTAINMENT"),
    (38, 75.00, "Comedy Show", "debit", "ENTERTAINMENT"),
    (39, 6.99, "Hulu", "debit", "ENTERTAINMENT"),
    (40, 22.50, "Bowling Alley", "debit", "ENTERTAINMENT"),

    # 41–50: Shopping
    (41, 89.00, "Amazon", "debit", "SHOPPING"),
    (42, 45.75, "Target", "debit", "SHOPPING"),
    (43, 120.00, "Clothing Store", "debit", "SHOPPING"),
    (44, 250.00, "Electronics Store", "debit", "SHOPPING"),
    (45, 16.80, "Dollar Store", "debit", "SHOPPING"),
    (46, 310.50, "Furniture Shop", "debit", "SHOPPING"),
    (47, 9.99, "Online App Store", "debit", "SHOPPING"),
    (48, 75.00, "Footwear Outlet", "debit", "SHOPPING"),
    (49, 15.49, "Bookstore", "debit", "SHOPPING"),
    (50, 200.00, "Appliance Store", "debit", "SHOPPING"),

    # 51–60: Utilities
    (51, 90.00, "Electric Bill", "debit", "UTILITIES"),
    (52, 45.00, "Internet Bill", "debit", "UTILITIES"),
    (53, 30.00, "Water Bill", "debit", "UTILITIES"),
    (54, 60.50, "Gas Bill", "debit", "UTILITIES"),
    (55, 22.00, "Trash Service", "debit", "UTILITIES"),
    (56, 49.99, "Phone Plan", "debit", "UTILITIES"),
    (57, 12.00, "Sewage Fee", "debit", "UTILITIES"),
    (58, 100.00, "Electric Bill", "debit", "UTILITIES"),
    (59, 38.75, "Mobile Data Add-On", "debit", "UTILITIES"),
    (60, 55.25, "Internet Bill", "debit", "UTILITIES"),

    # 61–70: Healthcare
    (61, 25.00, "Pharmacy", "debit", "HEALTHCARE"),
    (62, 75.00, "Urgent Care", "debit", "HEALTHCARE"),
    (63, 12.00, "Vitamin Store", "debit", "HEALTHCARE"),
    (64, 150.00, "Doctor Visit", "debit", "HEALTHCARE"),
    (65, 40.00, "Dental Checkup", "debit", "HEALTHCARE"),
    (66, 85.00, "Eye Clinic", "debit", "HEALTHCARE"),
    (67, 19.99, "Prescription", "debit", "HEALTHCARE"),
    (68, 200.00, "ER Visit Fee", "debit", "HEALTHCARE"),
    (69, 60.00, "Chiropractor", "debit", "HEALTHCARE"),
    (70, 35.50, "Lab Test", "debit", "HEALTHCARE"),

    # 71–80: Income (credit)
    (71, 2500.00, "Client Payment A", "credit", "INCOME"),
    (72, 1800.00, "Client Payment B", "credit", "INCOME"),
    (73, 3200.00, "Client Payment C", "credit", "INCOME"),
    (74, 900.00, "Small Project", "credit", "INCOME"),
    (75, 5000.00, "Salary", "credit", "INCOME"),
    (76, 1500.00, "Side Job", "credit", "INCOME"),
    (77, 2600.00, "Employer Payroll", "credit", "INCOME"),
    (78, 780.00, "Refund", "credit", "INCOME"),
    (79, 4200.00, "Bonus Payment", "credit", "INCOME"),
    (80, 150.00, "Cashback", "credit", "INCOME"),

    # 81–90: Savings / Transfers
    (81, 200.00, "Savings Deposit", "debit", "SAVINGS"),
    (82, 300.00, "Investment Fund", "debit", "SAVINGS"),
    (83, 150.00, "Emergency Fund", "debit", "SAVINGS"),
    (84, 400.00, "Long-term Savings", "debit", "SAVINGS"),
    (85, 50.00, "Round-Up Transfer", "debit", "SAVINGS"),
    (86, 100.00, "Crypto Purchase", "debit", "SAVINGS"),
    (87, 600.00, "Retirement Contribution", "debit", "SAVINGS"),
    (88, 75.00, "High-Yield Account", "debit", "SAVINGS"),
    (89, 500.00, "Portfolio", "debit", "SAVINGS"),
    (90, 20.00, "Micro Savings", "debit", "SAVINGS"),

    # 91–100: Miscellaneous + Edge Cases
    (91, 0.00, "Test Zero", "debit", "GROCERIES"),

    (93, 9999.99, "Luxury Purchase", "debit", "SHOPPING"),
    (94, 3.14, "Rounded Purchase", "debit", "DINING"),
    (95, 1.00, "Candy Shop", "debit", "DINING"),
    (96, 450.00, "Car Repair", "debit", "TRANSPORT"),
    (97, 800.00, "Insurance Payment", "debit", "HOUSING"),
    (98, 1200.00, "Rent Payment", "debit", "HOUSING"),
    (99, 250.00, "Random Charge", "debit", "OTHER"),
    (100, 5.00, "Unknown Merchant", "debit", "UNCATEGORIZED"),
    ]
    
    # Create income transactions
    for day_offset, amount, merchant, tx_type in income_data:
        tx = Transaction(
            user_id=user_id,
            amount=Decimal(str(amount)),
            merchant=merchant,
            type=tx_type,
            category="INCOME",
            timestamp=base_date - timedelta(days=days - day_offset),
            transactionId=f"TEST_INC_{day_offset}"
        )
        transactions.append(tx)
    
    # Create expense transactions
    for day_offset, amount, merchant, tx_type, category in expenses_data:
        tx = Transaction(
            user_id=user_id,
            amount=Decimal(str(amount)),
            merchant=merchant,
            type=tx_type,
            category=category,
            timestamp=base_date - timedelta(days=days - day_offset),
            transactionId=f"TEST_EXP_{day_offset}_{category}"
        )
        transactions.append(tx)
    
    db.bulk_save_objects(transactions)
    db.commit()
    
    print(f"✅ Created {len(transactions)} test transactions")
    print(f"   - Income: ${sum(t.amount for t in transactions if t.type == 'credit'):,.2f}")
    print(f"   - Expenses: ${sum(t.amount for t in transactions if t.type == 'debit'):,.2f}")
    return transactions


async def build_behavior_model_async(db, user_id: int):
    """Build behavior model from transactions (async)"""
    categorization_service = CategorizationService(
        gemini_api_key=os.getenv("GEMINI_API_KEY", "dummy_key")
    )
    engine = BehaviorEngine(categorization_service)
    
    # Delete existing model
    db.query(BehaviourModel).filter_by(user_id=user_id).delete()
    db.commit()
    
    # Build new model
    txs = db.query(Transaction).filter_by(user_id=user_id, type="debit").all()
    print(f"\n   Building model from {len(txs)} debit transactions...")
    
    for i, tx in enumerate(txs, 1):
        try:
            await engine.update_model(db, user_id, tx)
            db.commit()  # Commit after each update
            if i <= 3 or i % 10 == 0:
                print(f"   Processed tx {i}/{len(txs)}: {tx.category} - ${tx.amount} at {tx.merchant}")
        except Exception as e:
            print(f"   ⚠️  Error processing transaction {tx.id}: {e}")
            db.rollback()
            import traceback
            traceback.print_exc()
    
    # Refresh session to get latest data
    db.expire_all()
    model = db.query(BehaviourModel).filter_by(user_id=user_id).first()
    
    if model:
        stats = model.category_stats or {}
        print(f"\n✅ Behavior model built:")
        print(f"   - Categories tracked: {len(stats)}")
        print(f"   - Transaction count: {model.transaction_count}")
        
        if stats:
            print(f"\n   Category details:")
            for cat, cat_stats in list(stats.items())[:5]:  # Show first 5
                mean = cat_stats.get('mean', 0)
                count = cat_stats.get('count', 0)
                print(f"   - {cat}: ${mean:,.2f} avg ({count} transactions)")
        else:
            print(f"   ⚠️  No category stats saved!")
    else:
        print(f"\n❌ No behavior model created!")
    
    return model


def build_behavior_model(db, user_id: int):
    """Build behavior model from transactions (sync wrapper)"""
    return asyncio.run(build_behavior_model_async(db, user_id))


def test_single_scenario(db, user_id: int):
    """Test single spending scenario"""
    print("\n" + "="*60)
    print("TEST 1: Single Spending Scenario (20% reduction)")
    print("="*60)
    
    try:
        result = SimulationService.simulate_spending_scenario(
            db=db,
            user_id=user_id,
            scenario_type="reduction",
            target_percent=20.0,
            time_period_days=30
        )
        
        print(f"✅ Scenario generated successfully")
        print(f"   Baseline: ${result.baseline_monthly:,.2f}")
        print(f"   Projected: ${result.projected_monthly:,.2f}")
        print(f"   Change: ${result.total_change:,.2f}")
        print(f"   Annual impact: ${result.annual_impact:,.2f}")
        print(f"   Feasibility: {result.feasibility}")
        print(f"   Categories analyzed: {len(result.category_breakdown)}")
        print(f"\n   Top 3 recommendations:")
        for i, rec in enumerate(result.recommendations[:3], 1):
            rec_text = rec if isinstance(rec, str) else rec.get('recommendation', str(rec))
            print(f"   {i}. {rec_text}")
        
        return True
    except Exception as e:
        print(f"❌ Failed: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_comparison(db, user_id: int):
    """Test scenario comparison"""
    print("\n" + "="*60)
    print("TEST 2: Multiple Scenario Comparison")
    print("="*60)
    
    try:
        result = SimulationService.compare_scenarios(
            db=db,
            user_id=user_id,
            scenario_type="reduction",
            time_period_days=30,
            num_scenarios=3
        )
        
        print(f"✅ Comparison generated successfully")
        print(f"   Baseline: ${result.baseline_monthly:,.2f}")
        print(f"   Scenarios compared: {len(result.scenarios)}")
        print(f"   Recommended: {result.recommended_scenario_id}")
        print(f"\n   Scenarios:")
        for scenario in result.scenarios:
            print(f"   - {scenario.name}: ${scenario.projected_monthly:,.2f} "
                  f"(change: ${scenario.total_change:,.2f}, difficulty: {scenario.difficulty_score:.2f})")
        
        return True
    except Exception as e:
        print(f"❌ Failed: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_reallocation(db, user_id: int):
    """Test budget reallocation"""
    print("\n" + "="*60)
    print("TEST 3: Budget Reallocation")
    print("="*60)
    
    try:
        # Refresh session
        db.expire_all()
        
        # Get current spending to calculate dollar amounts
        model = db.query(BehaviourModel).filter_by(user_id=user_id).first()
        if not model or not model.category_stats:
            print("❌ No behavior model found - skipping reallocation test")
            return False
        
        stats = model.category_stats
        
        from app.utils.constants import DISCRETIONARY_CATEGORIES, ESSENTIAL_CATEGORIES
        
        # Find discretionary categories (sources for cuts)
        discretionary_cats = [cat for cat in DISCRETIONARY_CATEGORIES if cat in stats and stats[cat].get('mean', 0) > 0]
        # Find essential categories (targets for increases)
        essential_cats = [cat for cat in ESSENTIAL_CATEGORIES if cat in stats and stats[cat].get('mean', 0) > 0]
        
        print(f"   Discretionary categories: {discretionary_cats}")
        print(f"   Essential categories: {essential_cats}")
        
        if not discretionary_cats:
            print("❌ No discretionary spending to cut - skipping reallocation test")
            return False
        
        # Cut from highest discretionary spending
        source_cat = discretionary_cats[0]
        source_avg = stats.get(source_cat, {}).get("mean", 0)
        
        # Allocate to SAVINGS if no essential categories, otherwise use first essential
        target_cat = essential_cats[0] if essential_cats else "SAVINGS"
        target_avg = stats.get(target_cat, {}).get("mean", 0) if target_cat in stats else 0
        
        # Calculate dollar amounts (must sum to zero)
        cut_amount = -source_avg * 0.3  # Cut 30% from discretionary
        increase_amount = -cut_amount  # Move to essential/savings
        
        print(f"   Planning beneficial reallocation:")
        print(f"   - Cut {source_cat} (discretionary): ${cut_amount:,.2f} (from ${source_avg:,.2f})")
        print(f"   - Increase {target_cat} (essential/savings): +${increase_amount:,.2f} (from ${target_avg:,.2f})")
        print(f"   - Net change: ${(cut_amount + increase_amount):,.2f} (should be ~0)")
        
        result = SimulationService.simulate_reallocation(
            db=db,
            user_id=user_id,
            reallocations={
                source_cat: cut_amount,
                target_cat: increase_amount
            },
            time_period_days=30
        )
        
        print(f"✅ Reallocation simulated successfully")
        print(f"   Baseline: ${result.baseline_monthly:,.2f}")
        print(f"   Projected: ${result.projected_monthly:,.2f}")
        print(f"   Feasibility: {result.feasibility_assessment}")
        print(f"\n   Changes:")
        for change in result.reallocations:
            print(f"   - {change.category}: {change.change_percent:+.1f}% "
                  f"(${change.current_monthly:,.2f} → ${change.new_monthly:,.2f})")
        
        if result.warnings:
            print(f"\n   Warnings:")
            for warning in result.warnings:
                print(f"   ⚠️  {warning}")
        
        return True
    except Exception as e:
        print(f"❌ Failed: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_projection(db, user_id: int):
    """Test future projection"""
    print("\n" + "="*60)
    print("TEST 4: Future Spending Projection (6 months)")
    print("="*60)
    
    try:
        result = SimulationService.project_future_spending(
            db=db,
            user_id=user_id,
            projection_months=6,
            time_period_days=30,
            behavioral_changes={
                "DINING": -15.0,
                "ENTERTAINMENT": -20.0
            }
        )
        
        print(f"✅ Projection generated successfully")
        print(f"   Baseline monthly: ${result.baseline_monthly:,.2f}")
        print(f"   Total projected (6mo): ${result.total_projected:,.2f}")
        print(f"   Cumulative change: ${result.cumulative_change:,.2f}")
        print(f"   Annual impact: ${result.annual_impact:,.2f}")
        print(f"   Confidence: {result.confidence_level}")
        print(f"\n   Monthly breakdown:")
        for proj in result.monthly_projections[:3]:
            print(f"   - {proj.month_label}: ${proj.projected_spending:,.2f} "
                  f"(confidence: {proj.confidence:.2f})")
        
        return True
    except Exception as e:
        print(f"❌ Failed: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """Run all tests"""
    print("\n" + "🚀 " + "="*56 + " 🚀")
    print("  SIMULATION ENGINE TEST SUITE")
    print("🚀 " + "="*56 + " 🚀\n")
    
    db = SessionLocal()
    try:
        # Setup
        user = create_test_user(db)
        print(f"✅ Test user: {user.name} (ID: {user.id})")
        
        seed_test_transactions(db, user.id)
        build_behavior_model(db, user.id)
        
        # Run tests
        results = {
            "Single Scenario": test_single_scenario(db, user.id),
            "Scenario Comparison": test_comparison(db, user.id),
            "Budget Reallocation": test_reallocation(db, user.id),
            "Future Projection": test_projection(db, user.id)
        }
        
        # Summary
        print("\n" + "="*60)
        print("SUMMARY")
        print("="*60)
        passed = sum(results.values())
        total = len(results)
        
        for test_name, result in results.items():
            status = "✅ PASS" if result else "❌ FAIL"
            print(f"{status} - {test_name}")
        
        print(f"\n{passed}/{total} tests passed")
        
        if passed == total:
            print("\n🎉 All tests passed! Simulation engine is working.")
        else:
            print("\n⚠️  Some tests failed. Check errors above.")
        
    finally:
        db.close()


if __name__ == "__main__":
    main()
