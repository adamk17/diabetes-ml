import os

from dotenv import load_dotenv


class Config:
    def __init__(self):
        load_dotenv(dotenv_path="./.env")

        # Required enviroment variables
        required_env = []
        if os.getenv("USE_IAM_AUTH", "false").lower() != "true":
            # If IAM is not used, then traditional credentials are required
            required_env.extend(["DB_HOST", "MODEL_BUCKET"])
            if os.getenv("DB_IAM_AUTH", "false").lower() != "true":
                required_env.extend(["DB_USER", "DB_PASSWORD"])

        missing = [var for var in required_env if not os.getenv(var)]
        if missing:
            raise EnvironmentError(f"Missing environment variables: {', '.join(missing)}")

        # S3 configuration
        self.model_bucket = os.getenv("MODEL_BUCKET")
        self.model_prefix = os.getenv("MODEL_PREFIX", "tf_model")
        self.use_iam_auth = os.getenv("USE_IAM_AUTH", "false").lower() == "true"

        # DB configuration
        self.db_host = os.getenv("DB_HOST")
        self.db_port = int(os.getenv("DB_PORT", "5432"))
        self.db_user = os.getenv("DB_USER")
        self.db_password = os.getenv("DB_PASSWORD")
        self.db_name = os.getenv("DB_NAME", "predictions")
        self.db_pool_min = int(os.getenv("DB_POOL_MIN", "1"))
        self.db_pool_max = int(os.getenv("DB_POOL_MAX", "10"))
        self.db_iam_auth = os.getenv("DB_IAM_AUTH", "false").lower() == "true"
        self.db_ssl_mode = os.getenv("DB_SSL_MODE", "require")
        self.db_connect_timeout = int(os.getenv("DB_CONNECT_TIMEOUT", "5"))

        # CloudWatch configuration
        self.enable_cloudwatch = os.getenv("ENABLE_CLOUDWATCH", "false").lower() == "true"
        self.cloudwatch_log_group = os.getenv("CLOUDWATCH_LOG_GROUP", "model-prediction-api")

        # API version
        self.version = os.getenv("API_VERSION", "1.0.0")
