import uuid
from typing import Callable

from fastapi import Depends

from app.services.model_service import ModelService
from app.services.db_service import DatabaseService
from app.config import Config

config = Config()

model_service = ModelService(config)
model_service.initialize()

db_service = DatabaseService(config)
db_service.initialize()

def get_request_id() -> str:
    # Generate unique request ID
    return str(uuid.uuid4())

def get_model_service() -> ModelService:
    # Return the shared instance of ModelService
    return model_service

def get_db_service() -> DatabaseService:
    # Return the shared instance of DatabaseService
    return db_service

def get_config() -> Config:
    # Return the Config instance
    return config
