from pydantic import BaseModel, Field, field_validator
from typing import Dict, Any
import math

class InputData(BaseModel):
    x1: float = Field(..., description="Input feature 1")
    x2: float = Field(..., description="Input feature 2")
    x3: float = Field(..., description="Input feature 3")
    x4: float = Field(..., description="Input feature 4")
    x5: float = Field(..., description="Input feature 5")
    x6: float = Field(..., description="Input feature 6")
    x7: float = Field(..., description="Input feature 7")
    x8: float = Field(..., description="Input feature 8")
    x9: float = Field(..., description="Input feature 9")
    x10: float = Field(..., description="Input feature 10")

    @field_validator("*")
    @classmethod
    def validate_numeric(cls, v: float) -> float:
        # Validate that all input features are real numbers and not NaN/inf.
        if not isinstance(v, (int, float)):
            raise ValueError("All input features must be numeric (float or int).")
        if math.isnan(v) or math.isinf(v):
            raise ValueError("Input features cannot be NaN or infinite.")
        return float(v)

class PredictionResponse(BaseModel):
    prediction: float = Field(..., description="Predicted value from the model")
    timestamp: str = Field(..., description="UTC timestamp when the prediction was made (ISO format)")
    request_id: str = Field(..., description="Unique identifier for the request")

class HealthResponse(BaseModel):
    status: str = Field(..., description="Overall health status of the application ('ok' or 'degraded')")
    model_loaded: bool = Field(..., description="Indicates whether the ML model was loaded successfully")
    scaler_loaded: bool = Field(..., description="Indicates whether the scaler was loaded successfully")
    database: Dict[str, Any] = Field(..., description="Status and metrics related to the database connection")
    version: str = Field(..., description="API version currently running")
