
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient
import pytest

from app.main import app
from app.database.connection import Base, get_db


# Create a temporary SQLite database for testing
SQLALCHEMY_DATABASE_URL = "sqlite://"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool
)

TestingSessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)


# Use the test database instead of PostgreSQL
def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)


# Clean the database before every test
@pytest.fixture(autouse=True)
def clean_database():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield


# Test home endpoint
def test_home():
    response = client.get("/")

    assert response.status_code == 200
    assert response.json() == {
        "message": "Welcome to Sessions API"
    }


# Test health check
def test_health_check():
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {
        "status": "healthy"
    }


# Test creating a session
def test_create_session():
    response = client.post(
        "/sessions",
        json={
            "title": "DevOps Training",
            "description": "Learning Docker and AWS"
        }
    )

    assert response.status_code == 200
    assert response.json()["title"] == "DevOps Training"
    assert response.json()["description"] == "Learning Docker and AWS"
    assert "id" in response.json()


# Test getting all sessions
def test_get_all_sessions():
    response = client.get("/sessions")

    assert response.status_code == 200
    assert "sessions" in response.json()


# Test getting a session by ID
def test_get_session_by_id():
    create_response = client.post(
        "/sessions",
        json={
            "title": "Python Training",
            "description": "Learning Python"
        }
    )

    session_id = create_response.json()["id"]

    response = client.get(f"/sessions/{session_id}")

    assert response.status_code == 200
    assert response.json()["id"] == session_id


# Test updating a session
def test_update_session():
    create_response = client.post(
        "/sessions",
        json={
            "title": "Old Title",
            "description": "Old Description"
        }
    )

    session_id = create_response.json()["id"]

    response = client.put(
        f"/sessions/{session_id}",
        json={
            "title": "Updated DevOps Training",
            "description": "Learning Docker, AWS and Terraform"
        }
    )

    assert response.status_code == 200
    assert response.json()["title"] == "Updated DevOps Training"
    assert response.json()["description"] == "Learning Docker, AWS and Terraform"


# Test deleting a session
def test_delete_session():
    create_response = client.post(
        "/sessions",
        json={
            "title": "Delete Test",
            "description": "Testing deletion"
        }
    )

    session_id = create_response.json()["id"]

    response = client.delete(f"/sessions/{session_id}")

    assert response.status_code == 200
    assert response.json()["message"] == "Session deleted successfully"


# Test getting a nonexistent session
def test_session_not_found():
    response = client.get("/sessions/999999")

    assert response.status_code == 404
    assert response.json() == {
        "detail": "Session not found"
    }


# Test updating a nonexistent session
def test_update_session_not_found():
    response = client.put(
        "/sessions/999999",
        json={
            "title": "Unknown Session",
            "description": "This session does not exist"
        }
    )

    assert response.status_code == 404


# Test deleting a nonexistent session
def test_delete_session_not_found():
    response = client.delete("/sessions/999999")

    assert response.status_code == 404
