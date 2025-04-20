# 🩺 diabetes-ml

A complete machine learning pipeline for predicting diabetes progression using FastAPI, TensorFlow (Keras), PostgreSQL, Docker, AWS (S3 + RDS), and Terraform.

This project showcases how to train a regression model, serve it as an API, and deploy it with cloud infrastructure – all production-ready and containerized.

## 🚀 Features

* ✅ **ML model** trained with TensorFlow (Keras) on diabetes dataset
* ✅ **Scaler saved** for consistent inference  
* ✅ **FastAPI REST API** for real-time predictions
* ✅ **S3 model loading** in containerized app
* ✅ **PostgreSQL logging** of predictions for audit/monitoring
* ✅ **Prometheus metrics** via `/metrics`
* ✅ **Swagger UI** for interactive API docs
* ✅ **Docker + Docker Compose** for local development
* ✅ **Terraform infrastructure** (EC2, RDS, IAM, S3) for AWS
* ✅ **CloudWatch logging** from EC2 instance

## 🧠 ML Training Pipeline

Trained regression model that uses TensorFlow (Keras) on the classic diabetes dataset (`442 samples`, `10 features`).

### 🔧 Techniques Used

* **Model architecture**: 2 hidden layers with ReLU, batch normalization, dropout, and L2 regularization
* **Callbacks**:
   * Early stopping (patience = 30)
   * ReduceLROnPlateau for dynamic learning rate adjustment
* **Data**: StandardScaler applied to features
* **Artifacts saved**:
   * `tf_model.h5` – trained model
   * `scaler.pkl` – fitted scaler
   * Visualizations: feature importance, training history, prediction scatter

## ⚙️ API Overview

The FastAPI server exposes the following endpoints:

* `POST /predict` Takes 10 float features as input, returns prediction, timestamp, and unique request ID.
* `GET /health` Checks whether model, scaler, and database connection are ready.
* `GET /docs` Swagger UI for interactive documentation.
* `GET /metrics` Exposes Prometheus-compatible metrics.

## 🐳 Local Development with Docker Compose

To run the API and PostgreSQL locally using Docker:

1. **Make sure** you have Docker and Docker Compose installed.
2. **Create** a `.env.local` file inside the `api/` directory with all required environment variables.
3. **Run**:

```bash
docker-compose --env-file api/.env.local up --build
```

✅ What it does:
* Automatically pulls model + scaler from S3
* Spins up FastAPI + PostgreSQL containers
* Accessible at:
   * http://localhost:8000/docs → Swagger UI
   * http://localhost:8000/metrics → Prometheus metrics

To stop everything:

```bash
docker-compose down
```

## ☁️ AWS Infrastructure (Terraform)

This project uses **Terraform** to provision and manage:
* ✅ **EC2** instance to host the app (with Docker & SSH setup)
* ✅ **RDS (PostgreSQL)** for centralized prediction logging
* ✅ **IAM Roles & Policies** to manage access securely
* ✅ **CloudWatch Logs** for EC2 app monitoring
* ✅ **S3 (existing bucket)** for model & scaler storage

The Terraform deployment:
* Uses `user_data` to install Docker, clone app code, and launch the container
* Attaches IAM roles so the EC2 can access S3 + CloudWatch
* Uploads the app code with `null_resource` + PowerShell + SCP

You'll need:
* A key pair (`diabetes-key`) in `C:/users/USER/.ssh/`
* Valid AWS credentials (via environment or profile)

## 📂 Project Structure (simplified)
* `api/app/` → main FastAPI application (config, routes, services, etc.)
* `api/.env.local` → environment variables for local development (used by Docker)
* `api/Dockerfile` → image definition for the FastAPI app
* `api/upload_to_s3.py` → utility script to upload model artifacts to S3
* `api/train_model.py` → one-time script to train and export the model
* `docker-compose.yml` → local app + DB stack
* `requirements.txt` → Python dependencies for the container
* `trained_model/` → saved model, scaler, and training visualizations
* `terraform/` →  infrastructure as code for AWS (EC2, RDS, IAM, etc.)
* `terraform/modules/` → reusable Terraform modules: compute, database, storage
* `terraform/variables.tf` → variable declarations
* `terraform/terraform.tfvars` → environment-specific values

## 🛠 Deployment Summary

* ✅ Full deployment to AWS works out-of-the-box
* ✅ EC2 instance runs Docker containerized API
* ✅ Model + scaler pulled from S3 on boot
* ✅ Logs go to RDS and CloudWatch
* ✅ Code deployed via SCP through Terraform
* ✅ SSH enabled (via `diabetes-key.pem`)

---

### 📊 Visualizations & Analysis

#### 1. Feature Importance

Shows which features the model considered most influential based on the absolute weights of the first layer:

![Feature Importance](./trained_model/feature_importance.png)

#### 2. Training & Validation MAE

Model converges nicely without overfitting – early stopping helps retain generalization:

![Training Plot](./trained_model/training_plot.png)

#### 3. Prediction Scatter Plot

Visual comparison of predicted vs actual values on the test set:

![Prediction Scatter](./trained_model/prediction_scatter.png)

- Predictions generally follow the diagonal line (ideal prediction), especially for values below 150.
- There's noticeable spread in higher values (>200), indicating that the model struggles more in that range.
- Outliers show some samples with significant prediction errors.
- This is likely due to the **small dataset size (442 samples)**, which limits generalization capacity.