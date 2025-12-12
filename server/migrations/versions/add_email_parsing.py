"""add email parsing fields to user

Revision ID: add_email_parsing
Revises: 
Create Date: 2025-12-12

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'add_email_parsing'
down_revision = '67b35a1cdc38'  # Points to the previous migration
branch_labels = None
depends_on = None


def upgrade():
    # Add email_app_password column
    op.add_column('users', sa.Column('email_app_password', sa.String(), nullable=True))
    
    # Add email_parsing_enabled column
    op.add_column('users', sa.Column('email_parsing_enabled', sa.Boolean(), nullable=False, server_default='false'))


def downgrade():
    op.drop_column('users', 'email_parsing_enabled')
    op.drop_column('users', 'email_app_password')
