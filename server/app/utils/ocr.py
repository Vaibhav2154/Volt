from pydantic_ai import Agent
from pydantic_ai.models.google import GoogleModel
from pydantic_ai.providers.google import GoogleProvider
from pydantic_ai.messages import BinaryContent
from app.schemas.transaction_schemas import TransactionCreate
from app.core.config import settings
from typing import List


class OCRAgent:
    def __init__(self):
        self.provider = GoogleProvider(api_key=settings.gemini_api_key)
        self.model = GoogleModel("gemini-2.5-flash", provider=self.provider)

    async def extract_transaction(self, image: bytes) -> TransactionCreate:
        """Extract transaction details from an image using OCR and AI."""
        
        agent = Agent(
            model=self.model,
            output_type=TransactionCreate,
            system_prompt=(
                "You are a financial transaction OCR expert. Extract transaction details from the image. "
                "Fill in as many fields as possible from the visible data. Do NOT hallucinate. "
                "\n\nFields to extract:"
                "\n- amount (required): Transaction amount as a number"
                "\n- merchant (required): Merchant or payee name"
                "\n- timestamp (required): Transaction date and time"
                "\n- type (required): Either 'debit' or 'credit'"
                "\n- category: Spending category if visible"
                "\n- upiId: UPI ID if present"
                "\n- transactionId: Transaction or reference ID"
                "\n- balance: Account balance after transaction"
                "\n- bankName: Bank name if shown"
                "\n- accountNumber: Account number if visible"
                "\n- rawMessage: Raw transaction message/description"
                "\n- user_id: Set to 1 (default)"
                "\n\nOnly include fields that are clearly visible. Leave others as None."
            )
        )

        # Create BinaryContent for the image
        binary_image = BinaryContent(data=image, media_type='image/png')

        # Run OCR and extraction
        response = await agent.run(
            [
                "Extract the transaction details from this image. Fill in all visible fields.",
                binary_image
            ]
        )

        transaction = response.output
        print(f"Extracted transaction: {transaction}")

        return transaction
 
