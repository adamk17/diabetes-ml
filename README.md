# 🩺 diabetes-ml

A complete machine learning pipeline for predicting diabetes progression using FastAPI, TensorFlow (Keras), PostgreSQL, Docker, Kubernetes, Helm, AWS (S3 + RDS), and Terraform.

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
* ✅ **Terraform infrastructure** (EC2, RDS, IAM, S3, EKS, ECR) for AWS
* ✅ **CloudWatch logging** from EC2 instance or Kubernetes

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

* `POST /predict` - Takes 10 float features as input, returns prediction, timestamp, and unique request ID
* `GET /health` - Checks whether model, scaler, and database connection are ready
* `GET /docs` - Swagger UI for interactive documentation
* `GET /metrics` - Exposes Prometheus-compatible metrics

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

## ☁️ AWS Infrastructure with Terraform + EKS

The application can be fully deployed on Amazon EKS using Terraform and Helm – no manual Docker build/push required.

### 🧰 What gets provisioned:
* ✅ EKS cluster with managed node group
* ✅ ECR repository for Docker image
* ✅ Docker image built and pushed automatically
* ✅ Helm chart deployed with correct image from ECR
* ✅ Ingress controller (nginx) automatically installed
* ✅ LoadBalancer service exposes the app to the internet
* ✅ RDS for persistent PostgreSQL backend
* ✅ S3 integration for model loading
* ✅ CloudWatch logging from Kubernetes

### 🧪 How to deploy

From the `terraform/` directory:

```bash
terraform init
terraform apply
```

Terraform will:
* Create infrastructure (EKS, RDS, ECR, etc.)
* Build Docker image and push it to ECR
* Deploy application to EKS via Helm
* Return the Ingress hostname in the output

Example output:

```bash
ingress_nginx_service_hostname = "a04a4461460b04ed1b12464acf8ab028-8356960.eu-central-1.elb.amazonaws.com"
```

### 🌐 How to test deployed app

You can test your deployed app using:

```bash
curl http://a04a4461460b04ed1b12464acf8ab028-8356960.eu-central-1.elb.amazonaws.com/health
```

Or open it in your browser:

```bash
http://a04a4461460b04ed1b12464acf8ab028-8356960.eu-central-1.elb.amazonaws.com/docs
```

For local testing using hostname `diabetes-ml.local`, you can also edit your hosts file:

```bash
<external-lb-ip> diabetes-ml.local
```

To stop and delete everything:

```bash
terraform destroy
```

## 📂 Project Structure (simplified)
* `api/app/` → main FastAPI application
* `api/.env.local` → environment variables for local development
* `api/Dockerfile` → container definition
* `api/train_model.py` → script to train model and save artifacts
* `api/upload_to_s3.py` → utility script for pushing model/scaler to S3
* `docker-compose.yml` → local development stack
* `helm/` → Kubernetes deployment defined as a Helm chart (deployment, service, ingress, values)
* `trained_model/` → model, scaler, and visualization artifacts
* `terraform/` → full infrastructure as code
* `terraform/modules/` → reusable Terraform modules
* `terraform/variables.tf` → input variables
* `terraform/terraform.tfvars` → environment values

## 🛠 Deployment Summary

* ✅ `terraform apply` = full working deployment (infra + app + ECR + Helm)
* ✅ Model + scaler auto-loaded from S3
* ✅ Deployed to Kubernetes in EKS
* ✅ Accessible over internet via Ingress
* ✅ Docker image built/pushed locally during deployment
* ✅ No manual image tagging or Helm command needed

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
