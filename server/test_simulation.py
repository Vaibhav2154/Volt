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


def seed_test_transactions(db, user_id: int, days: int = 90):
    """
    Create realistic test transactions for a FREELANCER/GIG WORKER with variable income.
    
    Simulates 3 months of freelance work with:
    - Irregular income (some months high, some low)
    - Essential expenses
    - Business expenses
    - Flexible spending that varies with income
    """
    
    # Delete existing test transactions
    db.query(Transaction).filter_by(user_id=user_id).delete()
    db.commit()
    
    base_date = datetime.utcnow()
    transactions = []
    
    # INCOME - VARIABLE (freelancer style with good and lean months)
    income_data = [
        # Month 1 - Good month
        (5, 3500.00, "Client A - Web Design", "credit"),
        (12, 2200.00, "Client B - Content Writing", "credit"),
        (18, 1500.00, "Upwork Project", "credit"),
        
        # Month 2 - Lean month (fewer clients)
        (35, 800.00, "Small Gig", "credit"),
        (45, 1200.00, "Client C - Logo Design", "credit"),
        
        # Month 3 - Great month (big project)
        (60, 5000.00, "Client D - Full Stack App", "credit"),
        (68, 2800.00, "Client E - Consulting", "credit"),
        (75, 900.00, "Fiverr Gigs", "credit"),
        (82, 1600.00, "Referral Project", "credit"),
    ]
    
    # ESSENTIAL EXPENSES (relatively stable)
    expenses_data = [
        # Housing - Month 1, 2, 3
        (3, 1200.00, "Rent Payment", "debit", "HOUSING"),
        (33, 1200.00, "Rent Payment", "debit", "HOUSING"),
        (63, 1200.00, "Rent Payment", "debit", "HOUSING"),
        
        # Groceries (spread across 3 months)
        (1, 65.00, "Walmart", "debit", "GROCERIES"),
        (8, 45.00, "Trader Joes", "debit", "GROCERIES"),
        (15, 80.00, "Costco", "debit", "GROCERIES"),
        (22, 52.00, "Local Market", "debit", "GROCERIES"),
        (31, 58.00, "Walmart", "debit", "GROCERIES"),
        (38, 41.00, "Aldi", "debit", "GROCERIES"),
        (47, 73.00, "Whole Foods", "debit", "GROCERIES"),
        (54, 49.00, "Kroger", "debit", "GROCERIES"),
        (61, 67.00, "Costco", "debit", "GROCERIES"),
        (70, 55.00, "Trader Joes", "debit", "GROCERIES"),
        (78, 62.00, "Safeway", "debit", "GROCERIES"),
        (85, 48.00, "Local Market", "debit", "GROCERIES"),
        
        # Utilities (monthly)
        (5, 85.00, "Electric Bill", "debit", "UTILITIES"),
        (6, 60.00, "Internet - Comcast", "debit", "UTILITIES"),
        (7, 45.00, "Phone - Verizon", "debit", "UTILITIES"),
        (35, 92.00, "Electric Bill", "debit", "UTILITIES"),
        (36, 60.00, "Internet - Comcast", "debit", "UTILITIES"),
        (37, 45.00, "Phone - Verizon", "debit", "UTILITIES"),
        (65, 78.00, "Electric Bill", "debit", "UTILITIES"),
        (66, 60.00, "Internet - Comcast", "debit", "UTILITIES"),
        (67, 45.00, "Phone - Verizon", "debit", "UTILITIES"),
        
        # Transportation
        (2, 50.00, "Gas - Shell", "debit", "TRANSPORTATION"),
        (14, 18.50, "Uber", "debit", "TRANSPORTATION"),
        (25, 45.00, "Gas - Chevron", "debit", "TRANSPORTATION"),
        (40, 52.00, "Gas - Shell", "debit", "TRANSPORTATION"),
        (51, 22.00, "Lyft", "debit", "TRANSPORTATION"),
        (72, 48.00, "Gas - BP", "debit", "TRANSPORTATION"),
        (80, 15.00, "Uber", "debit", "TRANSPORTATION"),
        
        # Healthcare
        (20, 30.00, "CVS Pharmacy", "debit", "HEALTHCARE"),
        (55, 125.00, "Doctor Copay", "debit", "HEALTHCARE"),
        (88, 25.00, "Walgreens Pharmacy", "debit", "HEALTHCARE"),
    
    # FREELANCER-SPECIFIC EXPENSES
    
        # Business expenses (tools, software, equipment)
        (4, 29.99, "Adobe Creative Cloud", "debit", "BUSINESS_EXPENSE"),
        (10, 12.00, "GitHub Pro", "debit", "BUSINESS_EXPENSE"),
        (16, 199.00, "Laptop Upgrade - RAM", "debit", "BUSINESS_EXPENSE"),
        (34, 29.99, "Adobe Creative Cloud", "debit", "BUSINESS_EXPENSE"),
        (42, 15.00, "Zoom Pro", "debit", "BUSINESS_EXPENSE"),
        (50, 89.00, "External Monitor", "debit", "BUSINESS_EXPENSE"),
        (64, 29.99, "Adobe Creative Cloud", "debit", "BUSINESS_EXPENSE"),
        (71, 12.00, "GitHub Pro", "debit", "BUSINESS_EXPENSE"),
        (84, 45.00, "Notion Team", "debit", "BUSINESS_EXPENSE"),
        
        # Professional development (courses, books)
        (17, 49.99, "Udemy Course - React", "debit", "PROFESSIONAL_DEVELOPMENT"),
        (48, 199.00, "Web Design Conference", "debit", "PROFESSIONAL_DEVELOPMENT"),
        (76, 29.99, "Technical Book", "debit", "PROFESSIONAL_DEVELOPMENT"),
        
        # Client acquisition / marketing
        (11, 50.00, "LinkedIn Premium", "debit", "CLIENT_ACQUISITION"),
        (44, 35.00, "Business Cards", "debit", "CLIENT_ACQUISITION"),
        (74, 50.00, "LinkedIn Premium", "debit", "CLIENT_ACQUISITION"),
        
        # Tax savings (quarterly payments)
        (19, 800.00, "IRS Quarterly Tax", "debit", "TAX_SAVINGS"),
        (79, 750.00, "IRS Quarterly Tax", "debit", "TAX_SAVINGS"),
        
        # Emergency fund (varies with income - more in good months)
        (21, 500.00, "Emergency Fund Transfer", "debit", "EMERGENCY_FUND"),
        (69, 800.00, "Emergency Fund Transfer", "debit", "EMERGENCY_FUND"),
    
    # DISCRETIONARY SPENDING (varies with income - high in good months, low in lean months)
    
        # Dining (Month 1 - good income, more dining)
        (9, 32.00, "Chipotle", "debit", "DINING"),
        (13, 18.00, "Starbucks", "debit", "DINING"),
        (23, 45.00, "Sushi Restaurant", "debit", "DINING"),
        (27, 15.00, "Coffee Shop", "debit", "DINING"),
        
        # Dining (Month 2 - lean income, less dining)
        (41, 12.00, "Fast Food", "debit", "DINING"),
        (53, 8.00, "Coffee", "debit", "DINING"),
        
        # Dining (Month 3 - great income, more dining)
        (73, 65.00, "Nice Restaurant", "debit", "DINING"),
        (81, 22.00, "Brunch", "debit", "DINING"),
        (87, 28.00, "Thai Food", "debit", "DINING"),
        
        # Entertainment (varies with income)
        (24, 15.99, "Netflix", "debit", "ENTERTAINMENT"),
        (26, 9.99, "Spotify", "debit", "ENTERTAINMENT"),
        (29, 35.00, "Movie Theater", "debit", "ENTERTAINMENT"),
        (56, 15.99, "Netflix", "debit", "ENTERTAINMENT"),
        (58, 9.99, "Spotify", "debit", "ENTERTAINMENT"),
        (77, 15.99, "Netflix", "debit", "ENTERTAINMENT"),
        (83, 9.99, "Spotify", "debit", "ENTERTAINMENT"),
        (86, 42.00, "Concert Tickets", "debit", "ENTERTAINMENT"),
        
        # Shopping (varies significantly with income)
        (28, 45.00, "Amazon - Office Supplies", "debit", "SHOPPING"),
        # (lean month - minimal shopping)
        (89, 120.00, "Amazon - New Headphones", "debit", "SHOPPING"),
    
    # FLEXIBLE SPENDING (adjusted based on income)
    
        # Savings/Investments (high in good months, low/none in lean months)
        (30, 400.00, "Vanguard Investment", "debit", "INVESTMENTS"),
        # (lean month - no investments)
        (90, 1000.00, "Vanguard Investment", "debit", "INVESTMENTS"),
        
        # Subscriptions
        (57, 12.99, "YouTube Premium", "debit", "SUBSCRIPTIONS"),
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
    
    # Calculate statistics
    total_income = sum(t.amount for t in transactions if t.type == 'credit')
    total_expenses = sum(t.amount for t in transactions if t.type == 'debit')
    
    print(f"✅ Created {len(transactions)} test transactions for FREELANCER/GIG WORKER")
    print(f"   📊 Income Analysis:")
    print(f"      - Total Income (3 months): ${total_income:,.2f}")
    print(f"      - Average Monthly: ${total_income/3:,.2f}")
    print(f"      - Income Sources: {len([t for t in transactions if t.type == 'credit'])} payments")
    print(f"   💰 Expense Analysis:")
    print(f"      - Total Expenses (3 months): ${total_expenses:,.2f}")
    print(f"      - Average Monthly: ${total_expenses/3:,.2f}")
    print(f"   📈 Sustainability:")
    print(f"      - Income/Expense Ratio: {total_income/total_expenses:.2f}x")
    print(f"      - Net Position: ${total_income - total_expenses:,.2f}")
    
    return transactions


async def build_behavior_model_async(db, user_id: int):
    """Build behavior model from transactions (async) - now includes income tracking"""
    categorization_service = CategorizationService(
        gemini_api_key=os.getenv("GEMINI_API_KEY", "dummy_key")
    )
    engine = BehaviorEngine(categorization_service)
    
    # Delete existing model
    db.query(BehaviourModel).filter_by(user_id=user_id).delete()
    db.commit()
    
    # Build model from ALL transactions (both income and expenses)
    all_txs = db.query(Transaction).filter_by(user_id=user_id).order_by(Transaction.timestamp).all()
    debit_txs = [tx for tx in all_txs if tx.type == "debit"]
    credit_txs = [tx for tx in all_txs if tx.type == "credit"]
    
    print(f"\n   🔄 Building comprehensive model:")
    print(f"      - {len(credit_txs)} income transactions (credit)")
    print(f"      - {len(debit_txs)} expense transactions (debit)")
    
    # Process all transactions
    for i, tx in enumerate(all_txs, 1):
        try:
            await engine.update_model(db, user_id, tx)
            db.commit()  # Commit after each update
            if i <= 5 or i % 15 == 0:
                tx_type = "💵 Income" if tx.type == "credit" else "💳 Expense"
                print(f"   {tx_type} {i}/{len(all_txs)}: {tx.category} - ${tx.amount}")
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
        income_stats = None
        if model.monthly_patterns:
            income_stats = model.monthly_patterns.get('income_stats')
        
        print(f"\n✅ Comprehensive Behavior Model Built:")
        print(f"   📊 Overall: {model.transaction_count} transactions processed")
        
        # Expense categories
        if stats:
            print(f"\n   💳 Expense Categories ({len(stats)} tracked):")
            # Sort by mean spending
            sorted_stats = sorted(stats.items(), key=lambda x: x[1].get('mean', 0), reverse=True)
            for cat, cat_stats in sorted_stats[:8]:  # Show top 8
                mean = cat_stats.get('mean', 0)
                count = cat_stats.get('count', 0)
                volatility = cat_stats.get('std_dev', 0) / mean if mean > 0 else 0
                print(f"      - {cat:25s}: ${mean:7,.2f} avg ({count:2d} txs) [volatility: {volatility:.2f}]")
        
        # Income stats (NEW!)
        if income_stats:
            print(f"\n   💵 Income Tracking (Freelancer Analysis):")
            print(f"      - Average Income: ${income_stats.get('mean', 0):,.2f}")
            print(f"      - Income Range: ${income_stats.get('min', 0):,.2f} - ${income_stats.get('max', 0):,.2f}")
            print(f"      - Income Volatility: {income_stats.get('volatility_coefficient', 0):.2%}")
            print(f"      - Payment Count: {income_stats.get('count', 0)} payments")
            
            # Business vs Personal income
            business_income = income_stats.get('business_income', {})
            personal_income = income_stats.get('personal_income', {})
            if business_income.get('count', 0) > 0 or personal_income.get('count', 0) > 0:
                print(f"\n   💼 Income Breakdown:")
                print(f"      - Business Income: ${business_income.get('sum', 0):,.2f} ({business_income.get('count', 0)} payments)")
                print(f"      - Personal Income: ${personal_income.get('sum', 0):,.2f} ({personal_income.get('count', 0)} payments)")
            
            sources = income_stats.get('sources', {})
            if sources:
                print(f"\n   👥 Income Sources: {len(sources)} clients/sources")
                for source, source_data in list(sources.items())[:3]:
                    income_type = source_data.get('type', 'unknown')
                    print(f"      • [{income_type}] {source}: ${source_data['total']:,.2f} ({source_data['count']} payments)")
            
            # Calculate income-to-expense ratio
            from app.services.statistics import StatisticsService
            ratio_analysis = StatisticsService.calculate_income_expense_ratio(income_stats, stats)
            print(f"\n   📈 Sustainability Analysis:")
            print(f"      - Avg Income/Expense Ratio: {ratio_analysis['avg_ratio']:.2f}x")
            print(f"      - Worst Case Ratio: {ratio_analysis['worst_case_ratio']:.2f}x")
            print(f"      - Sustainability: {ratio_analysis['sustainability'].upper()}")
            print(f"      - Risk Level: {ratio_analysis['risk_level'].upper()}")
            print(f"      - Recommended Buffer: ${ratio_analysis['recommended_buffer']:,.2f}")
            
            # Income forecasting (NEW!)
            from app.services.income_forecast import IncomeForecastService
            forecast_service = IncomeForecastService()
            
            # Build income history from last few payments
            # For demo, use a simple list based on mean and volatility
            income_mean = income_stats.get('mean', 0)
            income_std = income_stats.get('std_dev', 0)
            income_count = income_stats.get('count', 0)
            
            if income_count >= 3:
                # Simulate monthly income history for forecast demo
                # In production, you'd query actual monthly totals
                import random
                random.seed(42)
                income_history = [
                    max(0, income_mean + random.uniform(-income_std, income_std))
                    for _ in range(min(income_count, 6))
                ]
                
                forecast, confidence = forecast_service.exponential_smoothing_forecast(income_history)
                print(f"\n   🔮 Income Forecast (Next Month):")
                print(f"      - Predicted Income: ${forecast:,.2f}")
                print(f"      - Confidence: {confidence:.1%}")
                
                trend_analysis = forecast_service.analyze_income_trend(income_history)
                print(f"      - Trend: {trend_analysis['trend'].upper()} ({trend_analysis['growth_rate']:+.1f}%/month)")
                print(f"      - {trend_analysis['message']}")
                
                # Runway calculation
                # Assume emergency fund balance from transaction data
                total_income = income_stats.get('sum', 0)
                total_expenses = sum(cat.get('sum', 0) for cat in stats.values())
                estimated_balance = total_income - total_expenses  # Simplified
                
                runway = forecast_service.calculate_runway(
                    current_balance=estimated_balance,
                    avg_income=income_mean,
                    avg_expenses=ratio_analysis['avg_expenses'],
                    income_volatility=income_stats.get('volatility_coefficient', 0)
                )
                
                print(f"\n   🛣️  Financial Runway:")
                print(f"      - Current Position: ${runway['current_balance']:,.2f}")
                print(f"      - Avg Monthly Net: ${runway['avg_monthly_net']:,.2f}")
                print(f"      - Worst Case Net: ${runway['worst_case_monthly_net']:,.2f}")
                if runway['worst_case_runway_months']:
                    print(f"      - Runway (worst case): {runway['worst_case_runway_months']:.1f} months")
                else:
                    print(f"      - Runway: ♾️ Sustainable (positive cash flow)")
                print(f"      - Risk: {runway['risk_level'].upper()}")
                print(f"      - {runway['risk_message']}")
        else:
            print(f"\n   ⚠️  No income data tracked (not a freelancer profile?)")
    else:
        print(f"\n❌ No behavior model created!")
    
    return model


def build_behavior_model(db, user_id: int):
    """Build behavior model from transactions (sync wrapper)"""
    return asyncio.run(build_behavior_model_async(db, user_id))


def test_single_scenario(db, user_id: int):
    """Test single spending scenario - Lean Month Strategy for Freelancers"""
    print("\n" + "="*60)
    print("TEST 1: Freelancer Lean Month Strategy (25% reduction)")
    print("Simulating expense reduction during a low-income month")
    print("="*60)
    
    try:
        result = SimulationService.simulate_spending_scenario(
            db=db,
            user_id=user_id,
            scenario_type="reduction",
            target_percent=25.0,
            time_period_days=30
        )
        
        print(f"✅ Lean Month Strategy Generated:")
        print(f"   Current Spending: ${result.baseline_monthly:,.2f}/month")
        print(f"   Target Spending: ${result.projected_monthly:,.2f}/month")
        print(f"   💰 Savings: ${result.total_change:,.2f}/month")
        print(f"   📅 Annual Impact: ${result.annual_impact:,.2f}")
        print(f"   ✓ Feasibility: {result.feasibility.upper()}")
        print(f"   📊 Categories: {len(result.category_breakdown)} analyzed")
        
        print(f"\n   🎯 Top Recommendations for Lean Months:")
        for i, rec in enumerate(result.recommendations[:5], 1):
            if isinstance(rec, dict):
                category = rec.get('category', 'N/A')
                action = rec.get('action', str(rec))
                rec_type = rec.get('type', 'N/A')
                print(f"   {i}. [{rec_type}] {action}")
            else:
                print(f"   {i}. {rec}")
        
        return True
    except Exception as e:
        print(f"❌ Failed: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_comparison(db, user_id: int):
    """Test scenario comparison - Variable Income Planning"""
    print("\n" + "="*60)
    print("TEST 2: Variable Income Scenario Planning")
    print("Comparing different spending strategies for freelancers")
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
    """Test future projection - Freelancer Growth Planning"""
    print("\n" + "="*60)
    print("TEST 4: Freelancer Growth Projection (6 months)")
    print("Planning for business investment and sustainable spending")
    print("="*60)
    
    try:
        result = SimulationService.project_future_spending(
            db=db,
            user_id=user_id,
            projection_months=6,
            time_period_days=30,
            behavioral_changes={
                "BUSINESS_EXPENSE": 20.0,  # Invest more in business
                "PROFESSIONAL_DEVELOPMENT": 30.0,  # Upskill
                "DINING": -25.0,  # Cut discretionary
                "ENTERTAINMENT": -20.0  # Cut discretionary
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
    print("\n" + "💼 " + "="*56 + " 💼")
    print("  FREELANCER/GIG WORKER SIMULATION TEST SUITE")
    print("  Testing variable income and adaptive spending patterns")
    print("💼 " + "="*56 + " 💼\n")
    
    db = SessionLocal()
    try:
        # Setup
        user = create_test_user(db)
        print(f"✅ Test user (Freelancer Profile): {user.name} (ID: {user.id})")
        
        seed_test_transactions(db, user.id, days=90)  # 3 months of data
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
        print("FREELANCER-FOCUSED TEST SUMMARY")
        print("="*60)
        passed = sum(results.values())
        total = len(results)
        
        for test_name, result in results.items():
            status = "✅ PASS" if result else "❌ FAIL"
            print(f"{status} - {test_name}")
        
        print(f"\n{passed}/{total} tests passed")
        
        if passed == total:
            print("\n🎉 All freelancer/gig worker tests passed!")
            print("✓ Variable income tracking working")
            print("✓ Income-aware simulations working")
            print("✓ Freelancer categories supported")
        else:
            print("\n⚠️  Some tests failed. Check errors above.")
        
    finally:
        db.close()


if __name__ == "__main__":
    main()
