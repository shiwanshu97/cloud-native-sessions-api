
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database.connection import Base, engine, get_db
from app.database.models import Session as SessionModel
from app.schemas.session import (
    SessionCreate,
    SessionResponse,
    SessionListResponse
)


# Initialize database when the application starts
@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title="Sessions API",
    lifespan=lifespan
)


# Home endpoint
@app.get("/")
def home():
    return {"message": "Welcome to Sessions API"}


# Health check endpoint
@app.get("/health")
def health_check():
    return {"status": "healthy"}


# Get all sessions
@app.get("/sessions", response_model=SessionListResponse)
def get_sessions(db: Session = Depends(get_db)):
    statement = select(SessionModel)
    sessions = db.scalars(statement).all()

    return {"sessions": sessions}


# Create a new session
@app.post("/sessions", response_model=SessionResponse)
def create_session(
    session: SessionCreate,
    db: Session = Depends(get_db)
):
    new_session = SessionModel(
        title=session.title,
        description=session.description
    )

    db.add(new_session)
    db.commit()
    db.refresh(new_session)

    return new_session


# Get a session by ID
@app.get("/sessions/{session_id}", response_model=SessionResponse)
def get_session(
    session_id: int,
    db: Session = Depends(get_db)
):
    session = db.get(SessionModel, session_id)

    if session is None:
        raise HTTPException(
            status_code=404,
            detail="Session not found"
        )

    return session


# Update an existing session
@app.put("/sessions/{session_id}", response_model=SessionResponse)
def update_session(
    session_id: int,
    updated_session: SessionCreate,
    db: Session = Depends(get_db)
):
    session = db.get(SessionModel, session_id)

    if session is None:
        raise HTTPException(
            status_code=404,
            detail="Session not found"
        )

    session.title = updated_session.title
    session.description = updated_session.description

    db.commit()
    db.refresh(session)

    return session


# Delete a session by ID
@app.delete("/sessions/{session_id}")
def delete_session(
    session_id: int,
    db: Session = Depends(get_db)
):
    session = db.get(SessionModel, session_id)

    if session is None:
        raise HTTPException(
            status_code=404,
            detail="Session not found"
        )

    deleted_session = {
        "id": session.id,
        "title": session.title,
        "description": session.description
    }

    db.delete(session)
    db.commit()

    return {
        "message": "Session deleted successfully",
        "session": deleted_session
    }
