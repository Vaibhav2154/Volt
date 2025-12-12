import re
from datetime import datetime
from typing import Dict, Optional


def parse_bank_email(subject: str, body: str, sender: str) -> Dict:
    """
    Parse a bank transaction email and return:
    {
      'amount', 'merchant', 'upiId', 'transactionId',
      'timestamp', 'type', 'balance', 'bankName',
      'accountNumber', 'rawMessage'
    }
    """
    raw = f"{subject}\n{body}"

    # amount
    amount = None
    m_amount = re.search(r"(?:INR|Rs\.?|₹)\s*([\d,]+\.?\d*)", raw, re.I)
    if m_amount:
        try:
            amount = float(m_amount.group(1).replace(",", ""))
        except ValueError:
            pass

    # merchant
    merchant = None
    m_merchant = re.search(r"spent at ([A-Za-z0-9 &.\-]+)", raw, re.I)
    if not m_merchant:
        m_merchant = re.search(r"to ([A-Za-z0-9@.\-]+)", raw, re.I)
    if m_merchant:
        merchant = m_merchant.group(1).strip()

    # UPI ID
    upiId: Optional[str] = None
    m_upi = re.search(r"UPI(?: ID)?:?\s*([a-zA-Z0-9@._-]+)", raw, re.I)
    if m_upi:
        upiId = m_upi.group(1).strip()

    # transaction ID
    transactionId: Optional[str] = None
    m_txn = re.search(r"(?:Txn|Transaction)\s*ID[: ]\s*([A-Za-z0-9\-]+)", raw, re.I)
    if m_txn:
        transactionId = m_txn.group(1).strip()

    # timestamp
    m_dt = re.search(r"(\d{1,2}-\d{1,2}-\d{4} \d{1,2}:\d{2})", raw)
    if m_dt:
        try:
            dt = datetime.strptime(m_dt.group(1), "%d-%m-%Y %H:%M")
            timestamp_iso = dt.isoformat()
        except ValueError:
            timestamp_iso = datetime.utcnow().isoformat()
    else:
        timestamp_iso = datetime.utcnow().isoformat()

    # type
    if re.search(r"debited|spent|sent|withdrawn", raw, re.I):
        txn_type = "debit"
    elif re.search(r"credited|received|deposited", raw, re.I):
        txn_type = "credit"
    else:
        txn_type = None

    # balance
    balance = None
    m_bal = re.search(
        r"(?:avl\.?\s*bal(?:ance)?|available balance|balance)[: ]*\s*(?:INR|Rs\.?|₹)?\s*([\d,]+\.?\d*)",
        raw,
        re.I,
    )
    if m_bal:
        try:
            balance = float(m_bal.group(1).replace(",", ""))
        except ValueError:
            pass

    # bank name from sender
    sender_lower = sender.lower()
    bankName = None
    if "hdfc" in sender_lower:
        bankName = "HDFC Bank"
    elif "icici" in sender_lower:
        bankName = "ICICI Bank"
    elif "sbi" in sender_lower:
        bankName = "SBI"
    elif "axis" in sender_lower:
        bankName = "Axis Bank"

    # account number (last 4)
    accountNumber = None
    m_acc = re.search(r"[Xx*]{2,}\s*(\d{4})", raw)
    if m_acc:
        accountNumber = m_acc.group(1)

    # category - basic categorization based on merchant/context
    category = None
    if merchant:
        merchant_lower = merchant.lower()
        if any(word in merchant_lower for word in ["swiggy", "zomato", "restaurant", "cafe", "food"]):
            category = "Food & Dining"
        elif any(word in merchant_lower for word in ["uber", "ola", "rapido", "transport", "petrol", "fuel"]):
            category = "Transportation"
        elif any(word in merchant_lower for word in ["amazon", "flipkart", "myntra", "shopping", "mall"]):
            category = "Shopping"
        elif any(word in merchant_lower for word in ["netflix", "spotify", "prime", "hotstar", "entertainment"]):
            category = "Entertainment"
        elif any(word in merchant_lower for word in ["electricity", "water", "gas", "bill", "recharge"]):
            category = "Bills & Utilities"
        elif any(word in merchant_lower for word in ["atm", "withdrawal"]):
            category = "Cash Withdrawal"
        else:
            category = "Others"

    return {
        "amount": amount,
        "merchant": merchant,
        "category": category,
        "upiId": upiId,
        "transactionId": transactionId,
        "timestamp": timestamp_iso,
        "type": txn_type,
        "balance": balance,
        "bankName": bankName,
        "accountNumber": accountNumber,
        "rawMessage": raw,
    }
