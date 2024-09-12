# latam-challenge

## Setup

Apis to be enabled:

- Billing API
- Cloud Functions API
- Pub/Sub API
- Bigquery API
- IAM API

## 1. Deploy infrastructure

### 1.1 Initialization

> **Constraint:** tested using Terraform v1.8.1

```bash
cd infra
terraform init
```

Create a new file called terraform.tfvars with the following information:

```md
project_id=<YOUR_GCP_PROJECT_ID>
region=<YOUR_GCP_REGION>
```

### 1.2 Plan

```bash
terraform plan -var-file=terraform.tfvars
```

### 1.3 Apply

```bash
terraform apply -var-file=terraform.tfvars
```

## 2. Test the deployed infrastructure

### 2.1 Ingest data

```bash
curl -m 310 -X POST https://<fn_ingest_data_url> \
-H "Authorization: bearer $(gcloud auth print-identity-token)" -H "Content-Type: application/json" \
-d '{
    "product_id": "45678",
    "product_name": "Laptop 2",
    "category": "Electronics",
    "unit_price": 999.99,
    "supplier": "TechSupplier Inc."
}'
```

### 2.2 Query data

```bash
curl -m 310 -X POST https://<fn_fetch_data_url> \
-H "Authorization: bearer $(gcloud auth print-identity-token)" -H "Content-Type: application/json" \
-d '{}'
```