from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.responses import JSONResponse
from datetime import datetime, timezone
import logging

from app.models.schemas import InputData, PredictionResponse, HealthResponse
from app.api.dependencies import (
    get_model_service,
    get_db_service,
    get_request_id,
    get_config
)
from app.services.model_service import ModelService
from app.services.db_service import DatabaseService
from app.config import Config

logger = logging.getLogger("diabetes_ml")

router = APIRouter()

@router.post(
    "/predict",
    response_model=PredictionResponse,
    summary="Run diabetes prediction",
    description="""
Run prediction based on 10 input features.  
Returns a float value representing diabetes disease progression.

All prediction data is logged to a PostgreSQL database  
along with a timestamp, unique request ID, and model response time.
""",
    tags=["Model"]
)
async def predict(
    data: InputData,
    request_id: str = Depends(get_request_id),
    model_service: ModelService = Depends(get_model_service),
    db_service: DatabaseService = Depends(get_db_service),
):
    # Make a prediction based on user input
    start_time = datetime.now(timezone.utc)
    features = [getattr(data, f"x{i}") for i in range(1, 11)]

    try:
        feature_tuple = tuple(features)
        prediction = model_service.predict(feature_tuple)
        processing_time = (datetime.now(timezone.utc) - start_time).total_seconds()

        db_service.log_prediction(
            request_id=request_id,
            features=features,
            prediction=prediction,
            status="ok",
            processing_time=processing_time
        )

        return {
            "prediction": prediction,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "request_id": request_id
        }

    except Exception as e:
        processing_time = (datetime.now(timezone.utc) - start_time).total_seconds()
        logger.error(f"Prediction error: {str(e)}")

        db_service.log_prediction(
            request_id=request_id,
            features=features,
            prediction=-1,
            status=f"error: {str(e)}",
            processing_time=processing_time
        )

        raise HTTPException(
            status_code=500,
            detail=f"Prediction failed: {str(e)}"
        )

@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Check API health status",
    description="""
Checks the health of key system components:
- model is loaded
- scaler is loaded
- database is available and responsive

Returns current system status and API version.
""",
    tags=["Monitoring"]
)
async def health_check(
    model_service: ModelService = Depends(get_model_service),
    db_service: DatabaseService = Depends(get_db_service),
    config: Config = Depends(get_config)
):
    # Health check endpoint for monitoring the app status
    model_loaded = model_service.model is not None
    scaler_loaded = model_service.scaler is not None

    db_status = db_service.check_connection()
    overall_status = "ok"
    response_status_code = status.HTTP_200_OK

    if not model_loaded or not scaler_loaded or db_status["status"] != "ok":
        overall_status = "degraded"
        response_status_code = status.HTTP_503_SERVICE_UNAVAILABLE

    health_response = {
        "status": overall_status,
        "model_loaded": model_loaded,
        "scaler_loaded": scaler_loaded,
        "database": db_status,
        "version": config.version
    }

    if overall_status != "ok":
        return JSONResponse(
            status_code=response_status_code,
            content=health_response
        )

    return health_response
