from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator
from contextlib import asynccontextmanager
import uvicorn

from app.config import Config
from app.services.model_service import ModelService
from app.services.db_service import DatabaseService
from app.api.endpoints import router
from app.utils.loggings import setup_logging

# Load configuration and logger
config = Config()
logger = setup_logging(config)

# Initialize services
model_service = ModelService(config)
db_service = DatabaseService(config)

# Define lifespan for startup and shutdown events
@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        model_service.initialize()
        db_service.initialize()
        logger.info("Application initialized successfully")
    except Exception as e:
        logger.critical(f"Critical error during initialization: {str(e)}")
        raise e

    yield  # App is running

    try:
        model_service.cleanup()
        logger.info("Resources released successfully")
    except Exception as e:
        logger.error(f"Error while releasing resources: {str(e)}")

# Initialize FastAPI app with lifespan
app = FastAPI(
    title="Diabetes-ml",
    version=config.version,
    description="API for executing predictions based on a trained ML model",
    lifespan=lifespan
)

# Include API router
app.include_router(router)

# Enable Prometheus metrics
Instrumentator().instrument(app).expose(app)

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
