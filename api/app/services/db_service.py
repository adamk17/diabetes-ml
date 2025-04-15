import os
import logging
import time
import boto3
from psycopg2.pool import SimpleConnectionPool
from contextlib import contextmanager
from datetime import datetime, timezone
from typing import List
from app.config import Config

logger = logging.getLogger("diabetes-ml")

class DatabaseService:
    def __init__(self, config: Config):
        self.config = config
        self.pool = None

    def initialize(self) -> bool:
        # Initialize the database connection pool
        try:
            connect_params = {
                "dbname": self.config.db_name,
                "host": self.config.db_host,
                "port": self.config.db_port,
                "sslmode": self.config.db_ssl_mode,
                "connect_timeout": self.config.db_connect_timeout,
                "application_name": "diabetes-ml-app"
            }

            if self.config.db_iam_auth:
                rds = boto3.client("rds")
                token = rds.generate_db_auth_token(
                    DBHostname=self.config.db_host,
                    Port=self.config.db_port,
                    DBUsername=self.config.db_user,
                    Region=os.getenv("AWS_REGION", "us-east-1")
                )
                connect_params["user"] = self.config.db_user
                connect_params["password"] = token
            else:
                connect_params["user"] = self.config.db_user
                connect_params["password"] = self.config.db_password

            self.pool = SimpleConnectionPool(
                self.config.db_pool_min,
                self.config.db_pool_max,
                **connect_params
            )

            self._ensure_table_exists()
            logger.info("Database connection initialized successfully")
            return True

        except Exception as e:
            logger.critical(f"Database initialization failed: {str(e)}")
            raise

    def _ensure_table_exists(self):
        # Ensure the logs table exists, create if not present
        try:
            with self.get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        CREATE TABLE IF NOT EXISTS logs (
                            id SERIAL PRIMARY KEY,
                            timestamp TIMESTAMPTZ NOT NULL,
                            request_id VARCHAR(50),
                            x1 FLOAT, x2 FLOAT, x3 FLOAT, x4 FLOAT, x5 FLOAT,
                            x6 FLOAT, x7 FLOAT, x8 FLOAT, x9 FLOAT, x10 FLOAT,
                            prediction FLOAT,
                            status VARCHAR(20),
                            processing_time FLOAT
                        )
                    """)
                    conn.commit()
                    logger.info("Verified that logs table exists")
        except Exception as e:
            logger.critical(f"Failed to create or verify logs table: {str(e)}")
            raise

    @contextmanager
    def get_connection(self):
        # Context manager for getting a connection from the pool
        conn = self.pool.getconn()
        try:
            yield conn
        finally:
            self.pool.putconn(conn)

    def log_prediction(
        self,
        request_id: str,
        features: List[float],
        prediction: float,
        status: str,
        processing_time: float
    ):
        # Log prediction results to the database
        try:
            with self.get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO logs 
                            (timestamp, request_id, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, 
                             prediction, status, processing_time)
                        VALUES 
                            (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """, (
                        datetime.now(timezone.utc), request_id, *features,
                        prediction, status, processing_time
                    ))
                    conn.commit()
        except Exception as e:
            logger.error(f"Failed to log prediction to database: {str(e)}")

    def check_connection(self):
        # Check connection health and return response time
        try:
            start_time = time.time()
            with self.get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT 1")

            response_time = time.time() - start_time
            logger.debug(f"Database responded in {response_time:.3f} seconds")

            return {
                "status": "ok",
                "response_time_ms": round(response_time * 1000, 2)
            }

        except Exception as e:
            logger.warning(f"Database connection check failed: {str(e)}")
            return {
                "status": "error",
                "message": str(e)
            }
