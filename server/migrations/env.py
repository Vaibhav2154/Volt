from logging.config import fileConfig
from sqlalchemy import pool
from alembic import context

from app.database import Base, engine as app_engine
from app.core.config import settings

# import all models here to register
from app.models import user, transactions, behaviour

config = context.config
config.set_main_option("sqlalchemy.url", settings.database_url)

fileConfig(config.config_file_name)
target_metadata = Base.metadata

def run_migrations_offline():
    url = settings.database_url
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        compare_type=True,
    )
    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online():
    connectable = app_engine
    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
        )
        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()