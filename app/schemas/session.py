
from pydantic import BaseModel, ConfigDict


class SessionCreate(BaseModel):
    title: str
    description: str


class SessionResponse(BaseModel):
    id: int
    title: str
    description: str

    model_config = ConfigDict(from_attributes=True)


class SessionListResponse(BaseModel):
    sessions: list[SessionResponse]
