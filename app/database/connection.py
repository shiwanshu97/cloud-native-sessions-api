
import os

from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from sqlalchemy.orm import declarative_base, sessionmaker


# Use DATABASE_URL when provided (local Docker Compose)
DATABASE_URL = os.getenv("DATABASE_URL")

if DATABASE_URL:
    database_url = DATABASE_URL

else:
    # Build the connection URL using ECS environment variables
    database_url = URL.create(
        drivername="postgresql+psycopg",
        username=os.getenv("DB_USER", "sessions_user"),
        password=os.getenv("DB_PASSWORD", "sessions_password"),
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "5432")),
        database=os.getenv("DB_NAME", "sessions_db")
    )


# Create the database engine
engine = create_engine(database_url)

# Create database sessions
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

Base = declarative_base()


# Database dependency for FastAPI endpoints
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()