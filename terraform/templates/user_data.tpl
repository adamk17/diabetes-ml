#!/bin/bash
set -e

# Save activation log
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
echo "Rozpoczęcie skryptu inicjalizacyjnego"

# System update & dependencies
apt-get update -y
apt-get install -y docker.io docker-compose awscli git

# Start Docker
systemctl enable docker
systemctl start docker

# Create working directory
mkdir -p /opt/diabetes-ml/api
mkdir -p /opt/diabetes-ml/trained_model
cd /opt/diabetes-ml

# Generate .env inside api/
cat > /opt/diabetes-ml/api/.env <<EOF
# AWS / S3
AWS_ACCESS_KEY_ID=${aws_access_key_id}
AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}
AWS_REGION=${aws_region}
MODEL_BUCKET=${model_bucket}
MODEL_PREFIX=tf_model
USE_IAM_AUTH=false

# RDS
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
DB_NAME=${db_name}
DB_POOL_MIN=1
DB_POOL_MAX=10
DB_IAM_AUTH=false
DB_SSL_MODE=require
DB_CONNECT_TIMEOUT=5

# CloudWatch
ENABLE_CLOUDWATCH=true
CLOUDWATCH_LOG_GROUP=/app/diabetes-ml

# API
API_VERSION=1.0.0
EOF

# Generate docker-compose.yml (top-level)
cat > /opt/diabetes-ml/docker-compose.yml <<EOF
version: '3'
services:
  api:
    build: .
    ports:
      - "80:8000"
    env_file:
      - ./api/.env
    volumes:
      - ./api:/app
      - ./trained_model:/app/trained_model
    restart: always
EOF

# Start the application
docker-compose up -d

echo "Initialization completed"
