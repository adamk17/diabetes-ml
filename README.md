# 🩺 diabetes-ml

A complete machine learning pipeline for predicting diabetes progression using FastAPI, TensorFlow (Keras), PostgreSQL, Docker, AWS (S3 + RDS), and Terraform.

This project showcases how to train a regression model, serve it as an API, and deploy it with cloud infrastructure – all production-ready and containerized.

---

## 🚀 Features

- ✅ **ML model** trained with TensorFlow (Keras) on diabetes dataset
- ✅ **Scaler saved** for consistent inference
- ✅ **FastAPI REST API** for real-time predictions
- ✅ **S3 model loading** in containerized app
- ✅ **PostgreSQL logging** of predictions for audit/monitoring
- ✅ **Prometheus metrics** via /metrics
- ✅ **Swagger UI** for interactive API docs
- ✅ **Docker + Docker Compose** support for local development and testing
- ✅ **Terraform infrastructure** (EC2, RDS, IAM, S3) for AWS

---

### 🧠 ML Training Pipeline

Trained regression model that uses TensorFlow (Keras) on the classic diabetes dataset (`442 samples`, `10 features`).

#### 🔧 Techniques Used

- **Model architecture**: 2 hidden layers with ReLU, batch normalization, dropout, and L2 regularization
- **Callbacks**:
  - Early stopping (patience = 30)
  - ReduceLROnPlateau for dynamic learning rate adjustment
- **Data**: StandardScaler applied to features
- **Artifacts saved**:
  - `tf_model.h5` – trained model
  - `scaler.pkl` – fitted scaler
  - Visualizations: feature importance, training history, prediction scatter

---

### ⚙️ API Overview

The FastAPI server exposes the following endpoints:

- `POST /predict`  
  Takes 10 float features as input, returns prediction, timestamp, and unique request ID.

- `GET /health`  
  Checks whether model, scaler, and database connection are ready.

- `GET /docs`  
  Built-in interactive documentation via Swagger UI.

- `GET /metrics`  
  Exposes Prometheus-compatible metrics (latency, request count, etc).

---

### 🐳 Local Development with Docker Compose

To run the API and PostgreSQL locally using Docker:

1. **Make sure** you have Docker and Docker Compose installed.
2. **Create** a `.env.local` file inside the `api/` directory with all required environment variables.
3. **Run** the following command from the project root:

```bash
docker-compose --env-file api/.env.local up --build
```

#### ✅ What it does:
* Automatically downloads the model (`.h5`) and scaler (`.pkl`) from S3 during startup
* Spins up a local PostgreSQL database container
* Exposes:
   * Prometheus metrics → http://localhost:8000/metrics
   * Swagger UI → http://localhost:8000/docs

To shut everything down:

```bash
docker-compose down
```

### 📂 Project Structure (simplified)
* `api/app/` → main FastAPI application (config, routes, services, etc.)
* `api/.env.local` → environment variables for local development (used by Docker)
* `api/Dockerfile` → image definition for the FastAPI app
* `api/upload_to_s3.py` → utility script to upload model artifacts to S3
* `api/train_model.py` → one-time script to train and export the model
* `docker-compose.yml` → local app + DB stack
* `requirements.txt` → Python dependencies for the container
* `trained_model/` → saved model, scaler, and training visualizations

---

### ☁️ AWS Integration

This project uses several AWS services:

- **Amazon S3** – to store trained model and scaler (`.h5`, `.pkl`)
- **Amazon RDS** – to log API predictions with timestamps and metadata
- **IAM** – to separate programmatic access (via environment)
- **Optional (future)**: EC2, CloudWatch, ElastiCache, Secrets Manager

Model and scaler are dynamically loaded from S3 with script.  
All S3 uploads are managed by a dedicated upload script using `boto3`.

Local setup does not require AWS RDS. By default, Docker Compose runs a local PostgreSQL instance.

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