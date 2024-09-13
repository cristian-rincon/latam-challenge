# latam-challenge

## Setup

### Pre-requisites

- [Gcloud CLI](https://cloud.google.com/sdk/docs/install?hl=es-419)
- [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [Python 3.9+](https://www.python.org/downloads/)

####  Optional

- [Terraform Docs](https://terraform-docs.io/)
- [NodeJS](https://nodejs.org/en/download/package-manager) (Pre-requisite for auto-changelog)
- [Auto-Changelog](https://www.npmjs.com/package/auto-changelog)

###  Apis to be enabled

> In case that you want to test from local, You (or a service account) must have enough permissions to enable the following APIs:

- Billing API (Just in case that you are about to [create a project from scratch](https://developers.google.com/workspace/guides/create-project#google-cloud-console))
- Cloud Functions API
- Pub/Sub API
- Bigquery API
- Identity and Access Management (IAM) API
- Cloud Resource Manager API

## 1. Infrastructure

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

## 2. Applications and CI/CD flow



### 2.1 Ingest data (HTTP API)

The data ingestion process is handled by a Cloud Function (HTTP), which triggers a Pub/Sub topic. The subscribed service then streams the incoming data into a BigQuery table for storage and analysis.

The Cloud function is deployed by Terraform, in a CD process orchestrated by GitHub Actions workflows. See details [here](<TOOD>)

Source code: /product_sales/ingestion

Request example:

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

## 3. CI/CD

The CI/CD process is orchestrated by [GitHub Actions](https://docs.github.com/en/actions). You can find the current workflows at `.github/workflows/` folder.

### 3.1 Create privileged service account for Terraform

A new service account (and service account key) must be created to grant privileged access to terraform. To do that, see this [documentation](https://cloud.google.com/iam/docs/service-accounts-create)

Required roles: Admin (See [how to manage access to service accounts](https://cloud.google.com/iam/docs/manage-access-service-accounts))

### 3.1 GitHub Actions Pre-Requisites

You need to create the following environments in your repository:

- development
- production

Additionally, the following environment secrets must be created:

GCP_PROJECT_ID: <the project id where you want to deploy the infrastructure>
GCP_REGION: <the region where you want to deploy the infrastructure>
GCP_CREDENTIALS_JSON: <the service account that you have created with enough permissions to create/manage the infrastructure resources>

Next, you will need to create a bucket to store the terraform state securely. See the following [documentation](https://cloud.google.com/docs/terraform/resource-management/store-state) to
store the state in a remote backend.