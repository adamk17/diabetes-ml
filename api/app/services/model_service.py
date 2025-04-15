import os
import tempfile
import boto3
import pickle
import tensorflow as tf
import numpy as np
import logging
from functools import lru_cache
from app.config import Config

logger = logging.getLogger('diabetes-ml')

class ModelService:
    def __init__(self, config: Config):
        self.config = config
        self.model = None
        self.scaler = None
        self.tempdir = tempfile.mkdtemp()
        
        if self.config.use_iam_auth:
            # Use IAM for S3 authentication
            self.s3 = boto3.client("s3")
        else:
            # Use traditional credentials
            self.s3 = boto3.client(
                "s3",
                aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
                aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
                region_name=os.getenv("AWS_REGION")
            )
        
    def initialize(self) -> bool:
        # Model and scaler initialization
        try:
            self._download_model()
            model_path = os.path.join(self.tempdir, "model.h5")
            self.model = tf.keras.models.load_model(model_path, compile=False)

            scaler_path = os.path.join(self.tempdir, "scaler.pkl")
            with open(scaler_path, "rb") as f:
                self.scaler = pickle.load(f)

            logger.info("Model and scaler initialized successfully")
            return True
        except Exception as e:
            logger.error(f"Error during model initialization: {str(e)}")
            raise
            
    def _download_model(self):
        # Download model and scaler from S3
        try:
            logger.info(f"Downloading model from S3: {self.config.model_bucket}/{self.config.model_prefix}")
            paginator = self.s3.get_paginator("list_objects_v2")
            
            found_any = False
            for page in paginator.paginate(Bucket=self.config.model_bucket, Prefix=self.config.model_prefix):
                for obj in page.get("Contents", []):
                    found_any = True
                    key = obj["Key"]
                    target = os.path.join(self.tempdir, key.replace(self.config.model_prefix + "/", ""))
                    os.makedirs(os.path.dirname(target), exist_ok=True)
                    self.s3.download_file(self.config.model_bucket, key, target)
                    logger.debug(f"Downloaded {key} -> {target}")
            if not found_any:
                raise FileNotFoundError("No model files found in S3 under the given prefix.")
        except Exception as e:
            logger.error(f"Error during downloading model from S3: {str(e)}")
            raise

    @lru_cache(maxsize=128)
    def predict(self, feature_tuple: tuple) -> float:
        # Making prediction with cache
        if not self.model or not self.scaler:
            raise ValueError("Model is not initialized")
            
        features = np.array([feature_tuple])
        scaled = self.scaler.transform(features)
        return float(self.model.predict(scaled)[0][0])
            
    def cleanup(self):
        # Cleaning resources
        if os.path.exists(self.tempdir):
            import shutil
            try:
                shutil.rmtree(self.tempdir)
            except Exception as e:
                logger.warning(f"Could not clean temporary directory: {str(e)}")
