# latam-challenge

[![CI](https://github.com/cristian-rincon/latam-challenge/actions/workflows/ci.yaml/badge.svg)](https://github.com/cristian-rincon/latam-challenge/actions/workflows/ci.yaml)
[![CD](https://github.com/cristian-rincon/latam-challenge/actions/workflows/cd.yaml/badge.svg)](https://github.com/cristian-rincon/latam-challenge/actions/workflows/cd.yaml)

Documentation in spanish can be found [here](./readme/README.ES.md)

## Contents

- [latam-challenge](#latam-challenge)
  - [Contents](#contents)
  - [Objective](#objective)
  - [Solution](#solution)
  - [Setup](#setup)
    - [Prerequisites](#prerequisites)
      - [Optional](#optional)
    - [APIs to Enable](#apis-to-enable)
  - [1. Infrastructure](#1-infrastructure)
    - [1.1 Initialization](#11-initialization)
    - [1.2 Plan](#12-plan)
    - [1.3 Apply](#13-apply)
  - [2. Applications and CI/CD Flow](#2-applications-and-cicd-flow)
    - [2.1 Data Ingestion (HTTP API)](#21-data-ingestion-http-api)
    - [2.2 Query Data](#22-query-data)
  - [3. CI/CD](#3-cicd)
    - [3.1 Branch Strategy](#31-branch-strategy)
    - [3.2 GitHub Actions Prerequisites](#32-github-actions-prerequisites)
      - [3.2.1 GitHub Environments](#321-github-environments)
      - [3.2.2 Resources Needed to Manage Terraform State in the Cloud](#322-resources-needed-to-manage-terraform-state-in-the-cloud)
      - [3.2.3 Environment Secrets](#323-environment-secrets)
    - [3.3 Proposal for System Integration Testing](#33-proposal-for-system-integration-testing)
      - [3.3.1. Integration Testing Proposal](#331-integration-testing-proposal)
        - [a. **Integration Tests for the Cloud Function that Queries BigQuery**](#a-integration-tests-for-the-cloud-function-that-queries-bigquery)
        - [b. **Integration Tests for the Cloud Function that Publishes to Pub/Sub**](#b-integration-tests-for-the-cloud-function-that-publishes-to-pubsub)
      - [3.3.2. Other Proposed Integration Tests](#332-other-proposed-integration-tests)
        - [a. **Complete Interaction Tests between Cloud Functions, BigQuery, and Pub/Sub**](#a-complete-interaction-tests-between-cloud-functions-bigquery-and-pubsub)
        - [b. **Latency and Response Time Tests**](#b-latency-and-response-time-tests)
      - [3.3.3. Identification of Critical Points and Testing Proposals](#333-identification-of-critical-points-and-testing-proposals)
      - [3.3.4. Proposals for Strengthening the System](#334-proposals-for-strengthening-the-system)
    - [4. Metrics and Monitoring](#4-metrics-and-monitoring)
      - [4.1. Proposal for 3 Critical Metrics to Evaluate System Health and Performance](#41-proposal-for-3-critical-metrics-to-evaluate-system-health-and-performance)
      - [4.2. Proposed Visualization Tool: **Google Cloud Monitoring (Stackdriver)**](#42-proposed-visualization-tool-google-cloud-monitoring-stackdriver)
      - [4.3. Implementation of Visualization Tool in the Cloud](#43-implementation-of-visualization-tool-in-the-cloud)
      - [4.4. Scaling to 50 Similar Systems and New Visualization Methods](#44-scaling-to-50-similar-systems-and-new-visualization-methods)
      - [4.5. Challenges or Limitations in System Observability at Scale](#45-challenges-or-limitations-in-system-observability-at-scale)
    - [5 Alerts and SRE](#5-alerts-and-sre)
      - [5.1. Rules and Thresholds for Triggering Alerts](#51-rules-and-thresholds-for-triggering-alerts)
        - [a. **Cloud Functions Latency**](#a-cloud-functions-latency)
        - [b. **Pub/Sub Error Rate**](#b-pubsub-error-rate)
        - [c. **BigQuery Query Times**](#c-bigquery-query-times)
      - [5.2. SLIs and SLOs](#52-slis-and-slos)
        - [a. **Cloud Functions Latency**](#a-cloud-functions-latency-1)
        - [b. **Pub/Sub Error Rate**](#b-pubsub-error-rate-1)
        - [c. **BigQuery Availability**](#c-bigquery-availability)
      - [Why Other Metrics Were Discarded](#why-other-metrics-were-discarded)

## Objective

Develop a cloud-based system to ingest, store, and expose data using IaC (Infrastructure as Code) and deployment with CI/CD workflows. Perform quality testing, monitoring, and alerts to ensure and monitor the system's health.

## Solution

The proposed solution consists of a system that ingests, stores, and exposes data using Google Cloud resources optimized for a data flow that uses a pub/sub schema.

The following components will be used for this solution:

- Google Cloud Platform
  - IAM: Roles and Service Accounts
  - Pub/Sub: Topics and Subscriptions
  - Cloud Run Functions: Data Ingestion and Query
  - BigQuery: Datasets and Tables for data storage (focused on data analytics)
- GitHub:
  - Repository: For storing the source code
  - Actions: For orchestrating CI/CD workflows
  - Environments: For managing deployments, secrets, and variables across different environments
  - Security:
    - Notifications: View or disclose security notices for this repository
    - Secret Scanning Alerts: Receive notifications when a secret is pushed to this repository

## Setup

### Prerequisites

- [Gcloud CLI](https://cloud.google.com/sdk/docs/install?hl=en)
- [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [Python 3.9+](https://www.python.org/downloads/)

#### Optional

- [Terraform Docs](https://terraform-docs.io/)
- [NodeJS](https://nodejs.org/en/download/package-manager) (Prerequisite for auto-changelog)
- [Auto-Changelog](https://www.npmjs.com/package/auto-changelog)

### APIs to Enable

If you wish to perform local testing, you (or a service account) must have sufficient permissions to enable the following APIs:

- Billing API (Only if you need to [create a project from scratch](https://developers.google.com/workspace/guides/create-project#google-cloud-console))
- Cloud Functions API
- Pub/Sub API
- BigQuery API
- Identity and Access Management (IAM) API
- Cloud Resource Manager API

## 1. Infrastructure

### 1.1 Initialization

> **Important:** Tested with Terraform v1.8.1

```bash
cd infra
terraform init
```

Create a new file named `terraform.tfvars` with the following information:

```md
project_id=<YOUR_GCP_PROJECT_ID>
region=<YOUR_GCP_REGION>
environment=<ENVIRONMENT_NAME>
```

### 1.2 Plan

```bash
terraform plan -var-file=terraform.tfvars
```

### 1.3 Apply

```bash
terraform apply -var-file=terraform.tfvars
```

## 2. Applications and CI/CD Flow

For this challenge, a use case was developed focusing on ingesting sales data of products.

The schema for the table to be populated is as follows:

```tf
  schema = <<EOF
  [
    {
      "name": "product_id",
      "type": "STRING",
      "mode": "REQUIRED"
    },
    {
      "name": "product_name",
      "type": "STRING",
      "mode": "REQUIRED"
    },
    {
      "name": "category",
      "type": "STRING",
      "mode": "REQUIRED"
    },
    {
      "name": "unit_price",
      "type": "FLOAT",
      "mode": "REQUIRED"
    },
    {
      "name": "supplier",
      "type": "STRING",
      "mode": "REQUIRED"
    }
  ]
    EOF
```

### 2.1 Data Ingestion (HTTP API)

The data ingestion process is managed by a [Cloud Function](https://cloud.google.com/functions?hl=en) (HTTP), which triggers a Pub/Sub topic. The subscribed service then streams the incoming data to a BigQuery table for storage and analysis.

> Terraform deploys the [Cloud Function](https://cloud.google.com/functions?hl=en) in a CD process orchestrated by GitHub Actions workflows. Details [here](#3-cicd)

Source Code: /product_sales/ingestion

Example request:

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

### 2.2 Query Data

The query process is made possible by a Cloud Function (HTTP) that queries the top 10 records stored in the BigQuery data warehouse.

> Terraform deploys the Cloud Function in a CD process orchestrated by GitHub Actions workflows. Details [here](#3-cicd)

Source Code: /product_sales/fetch

Example request:

```bash
curl -m 310 -X POST https://<fn_fetch_data_url> \
-H "Authorization: bearer $(gcloud auth print-identity-token)" -H "Content-Type: application/json" \
-d '{}'
```

## 3. CI/CD

The CI/CD process is organized by [GitHub Actions](https://docs.github.com/en/actions). You can find the current workflows in the `.github/workflows/` folder.

### 3.1 Branch Strategy

The repository is organized to use [Gitflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow#:~:text=What%20is%20Gitflow%3F,who%20popularized%20it.). As such, there is a `main` branch for production, a `develop` branch for development, and it is suggested to create branches from `develop` for making changes or improvements, and then merge those changes into `develop`, and finally into `main`.

### 3.2 GitHub Actions Prerequisites

#### 3.2.1 GitHub Environments

You need to create the following [environments](https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment) in your repository:

- development
- production

#### 3.2.2 Resources Needed to Manage Terraform State in the Cloud

You should create a new service account (and a service account key) to provide Terraform with privileged access. For this, refer to this [documentation](https://cloud.google.com/iam/docs/service-accounts-create).

Necessary roles: Administrator (see [how to manage access to service accounts](https://cloud.google.com/iam/docs/manage-access-service-accounts)).

Next, you will need to create a bucket to securely store the Terraform state. Refer to the following [documentation](https://cloud.google.com/docs/terraform/resource-management/store-state) for storing the state in a remote backend.

Once the bucket has been created, replace the bucket name in the `infra/provider.tf` file on line 9.

```tf
  backend "gcs" {
    bucket = "<SET_THE_BUCKET_NAME>"
    prefix = "terraform/state"
  }
```

#### 3.2.3 Environment Secrets

Additionally, you need to create the following [environment secrets](https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment#environment-secrets):

- GCP_PROJECT_ID: <the project id where you want to deploy the infrastructure>
- GCP_REGION: <the region where you want to deploy the infrastructure>
- GCP_CREDENTIALS_JSON: <the JSON content of the service account you created with sufficient permissions to create/manage the infrastructure resources>

Once these configurations are set up, GitHub Workflow triggers will activate when the rules specified in the `.github/workflows/ci.yaml` and `.github/workflows/cd.yaml` files are met.

### 3.3 Proposal for System Integration Testing

The system to be tested includes the following components:

- **Cloud Functions**:
   1. A function that queries data from a BigQuery table.
   2. Another function that sends messages to a Pub/Sub topic.
- **BigQuery**: A table housed in a dataset.
- **Pub/Sub**: A topic and subscription that handle dynamic messages.

#### 3.3.1. Integration Testing Proposal

##### a. **Integration Tests for the Cloud Function that Queries BigQuery**

**Objective**: Ensure that the function can correctly interact with BigQuery and return data in JSON format.

**Proposed Tests**:

1. **Basic Data Query**:
   - Verify that the function correctly queries data from the BigQuery table and returns the expected results.
   - Test different scenarios with data tables of varying sizes (small, medium, and large).

2. **Response Field Validation**:
   - Verify that the returned fields (product_id, product_name, category, unit_price, supplier) contain the correct values in each row and that the JSON structure matches the expected format.

3. **Error Handling**:
   - Simulate errors such as lack of permissions (`bigquery.jobs.create`), non-existent tables, or incorrect datasets, and validate that the function handles these errors correctly by returning appropriate responses (e.g., 404 if the table is not found, 500 for server errors).

**Implementation**:

- Use mocks to simulate interactions with BigQuery and isolate the Cloud Function's functionality.
- Run the Cloud Function with real BigQuery data for more comprehensive testing.

##### b. **Integration Tests for the Cloud Function that Publishes to Pub/Sub**

**Objective**: Verify that the function correctly publishes messages to Pub/Sub and handles errors appropriately.

**Proposed Tests**:

1. **Successful Message Publication**:
   - Send a sample message with the required fields (product_id, product_name, category, etc.) and validate that the message is correctly published to the Pub/Sub topic.

2. **Field Validation**:
   - Verify that all mandatory fields are sent and that the message format is correct.

3. **Error Handling**:
   - Simulate errors such as lack of permissions in Pub/Sub or a non-existent topic, and check that the function responds appropriately.

**Implementation**:

- Use mocks for Pub/Sub in development and test environments.
- Validate publications in a staging environment using a real topic and subscription.

#### 3.3.2. Other Proposed Integration Tests

##### a. **Complete Interaction Tests between Cloud Functions, BigQuery, and Pub/Sub**

**Objective**: Validate the complete data flow, from querying BigQuery to publishing to Pub/Sub, ensuring that the functions work correctly together.

**Proposed Tests**:

1. **Complete Data Flow**:
   - Extract data from BigQuery using the first Cloud Function, send the results to the second function via a Pub/Sub message, and verify that the message is processed correctly.

2. **High Data Load Simulation**:
   - Perform load testing to validate system behavior when processing large volumes of data from BigQuery and publishing messages in bulk to Pub/Sub.

##### b. **Latency and Response Time Tests**

**Objective**: Measure the response time of Cloud Functions under different load conditions to ensure optimal performance.

**Proposed Tests**:

1. **Latency Measurement**:
   - Measure the execution time from querying BigQuery to publishing to Pub/Sub.
   - Record response times under various load conditions.

2. **Timeout Simulation**:
   - Simulate longer wait times in querying BigQuery or publishing to Pub/Sub, and measure how these affect the overall system.

#### 3.3.3. Identification of Critical Points and Testing Proposals

**Critical Points**:

1. **Delays in BigQuery Queries**:
   - If the BigQuery table is very large or the query is complex, there may be high response times.

2. **Overload in Pub/Sub**:
   - Mass message publishing to Pub/Sub could cause system overload or delays in message delivery.

3. **Scalability of Cloud Functions**:
   - Under high demand, Cloud Functions might run out of resources, causing errors or prolonged wait times.

**Testing Proposals for Critical Points**:

- **Load Testing**: Simulate processing large volumes of data and messages, measuring how these impact execution time and system capacity.
- **Timeout Testing**: Simulate failures in BigQuery or Pub/Sub to observe system behavior under prolonged wait times.
- **Concurrency Testing**: Simulate multiple simultaneous invocations of the functions to verify if Cloud Functions scale properly without collapsing.

#### 3.3.4. Proposals for Strengthening the System

**a. Caching BigQuery Queries**:

- Implement a caching system for common queries, so that the same query doesn’t need to be executed repeatedly.
- Use a TTL (time-to-live) policy in the caches to ensure data is updated without causing unnecessary load.

**b. Implement Retries in Pub/Sub**:

- Configure automatic retries in case of failures in message publishing to Pub/Sub, ensuring that messages are not lost due to temporary errors.

**c. Monitoring and Alerts**:

- Use tools like **Stackdriver** (now Google Cloud Monitoring) to monitor system performance metrics, including response times, errors, and resource usage.
- Set up automatic alerts for anomalous response times or high error rates.

**d. Use of Circuit Breakers**:

- Implement a **circuit breaker** pattern to protect the system in case of continuous failures in BigQuery or Pub/Sub, avoiding overloading the system with unnecessary retries.

**e. Decoupling via Pub/Sub**:

- Ensure that functions are sufficiently decoupled using Pub/Sub as a robust message queue, allowing the ingestion function and the query function to work independently without blocking.

This proposal ensures a comprehensive approach to testing and strengthening the system, addressing both functionality and potential performance and scalability issues.

### 4. Metrics and Monitoring

#### 4.1. Proposal for 3 Critical Metrics to Evaluate System Health and Performance

In addition to basic metrics like **CPU, RAM, and DISK USAGE**, the following critical metrics are proposed to gain a deeper understanding of the system’s health:

1. **Cloud Functions Latency**:
   - **Description**: Total time a Cloud Function takes to process a request, from start to final response. This includes query time in BigQuery and publication time in Pub/Sub.
   - **Importance**: High latency may indicate performance issues in BigQuery or Pub/Sub, bottlenecks, or overloads in Cloud Functions.

2. **Pub/Sub Error Rate**:
   - **Description**: The proportion of messages that fail to publish or are not delivered correctly in the Pub/Sub system, divided by the total number of processed messages.
   - **Importance**: A high error rate in Pub/Sub would indicate issues with message delivery or communication failures between systems, which could affect data integrity.

3. **Query Times and Success Rate in BigQuery**:
   - **Description**: The time each query to BigQuery takes, as well as the percentage of successful queries versus failed ones (due to permission issues, resource overloads, or malformed queries).
   - **Importance**: Identifying failures or prolonged wait times in BigQuery allows for decisions on query optimization or improving infrastructure to handle more load.

#### 4.2. Proposed Visualization Tool: **Google Cloud Monitoring (Stackdriver)**

**Metrics to Display**:

1. **Cloud Functions Latency**:
   - Display a line or bar chart showing average, maximum, and minimum latency of functions in real-time and over selected time periods.
   - Benefit: Quickly identifies if any function is taking too long to respond, which could indicate bottlenecks or scalability issues.

2. **Pub/Sub Errors**:
   - A pie chart showing the ratio of successful messages versus failed ones, along with a trend chart showing if errors are increasing or decreasing over time.
   - Benefit: Facilitates detection of message delivery problems and communication issues between different systems.

3. **BigQuery Query Times**:
   - A scatter plot or bar chart showing average query times, highlighting queries that fail or exceed a set time threshold.
   - Benefit: Allows engineering teams to identify costly queries that may need optimization or that are overloading the system.

**How This Information Enables Strategic Decision-Making**:

- **Elevated Latency**: If latency metrics for Cloud Functions start increasing, teams might decide to optimize BigQuery queries, increase Cloud Functions capacity, or introduce caching mechanisms to reduce response times.
- **Pub/Sub Error Rate**: An increase in Pub/Sub errors might prompt reviews of publishing permissions, topic capacity, or the implementation of automatic retry strategies.
- **High Query Times in BigQuery**: Long-running queries could suggest the need to review indexing, partition tables, or increase BigQuery capacity to handle the load.

#### 4.3. Implementation of Visualization Tool in the Cloud

Implementing **Google Cloud Monitoring** (Stackdriver) would be straightforward as it is fully integrated with the Google Cloud Platform (GCP) ecosystem. The steps for implementation are as follows:

1. **Configure Cloud Functions Monitoring**:
   - Enable **Google Cloud Monitoring** to capture metrics for Cloud Functions, such as execution time, invocations, and errors.

2. **Monitor Pub/Sub**:
   - Use the Google Cloud Monitoring agent to capture metrics for Pub/Sub, such as message publishing rate, delivery time, and errors.

3. **Monitor BigQuery**:
   - Integrate specific metrics for BigQuery, such as query times and success/failure rates.

4. **Custom Dashboards**:
   - Create custom dashboards in Google Cloud Monitoring to visualize metrics in real-time and allow historical performance analysis.

5. **Alerts and Notifications**:
   - Set up alerts based on established thresholds for each metric (e.g., latency above X ms, Pub/Sub error rate above Y%).

**Metric Collection**:

- Each system component (Cloud Functions, BigQuery, Pub/Sub) already generates and exposes performance metrics that can be automatically collected by Google Cloud Monitoring. Custom metrics can also be included if additional system state details are needed.

#### 4.4. Scaling to 50 Similar Systems and New Visualization Methods

**How Visualization Would Change**:

- **Metric Aggregation**: With 50 systems, it would be necessary to aggregate metrics at the cluster or system group level, rather than monitoring each individually. Graphs could show average, worst-case, and best-case performance across all systems.
  
- **Filtering by Systems**: Include options to filter dashboards and metrics by specific systems or groups, to perform more precise diagnostics when needed.

- **Additional Metrics**:
   1. **Horizontal Scalability Rate**: A metric measuring how the system scales horizontally under increased load, comparing if the performance of additional systems is consistent.
   2. **Pub/Sub Congestion Rate**: If 50 systems are interacting with the same Pub/Sub topics, monitoring if the messaging system becomes congested could be useful.
   3. **Load Balancing**: Check if the workload is evenly distributed among Cloud Functions or if some systems are overloaded.

#### 4.5. Challenges or Limitations in System Observability at Scale

**Challenges or Limitations**:

1. **Data Noise**: As systems scale, massive volumes of monitoring data will be generated, which could make it difficult to identify important signals (issues) amid the noise. Effective filtering and aggregation strategies are needed.

2. **Monitoring Costs**: At larger scales, the costs of storing and processing metrics could increase significantly, requiring a balance between the depth of observability and the cost of maintaining it.

3. **Unexpected Bottlenecks**: Horizontal scalability may introduce new bottlenecks that were not evident in smaller environments, such as Pub/Sub saturation or limits on the number of concurrent BigQuery connections.

4. **Complexity in Problem Correlation**: With 50 interconnected systems, correlating issues between components may become complex. If not managed well, it could be challenging to identify specific systems or interactions causing widespread problems.

These challenges can be addressed with careful scalability planning and appropriate visualization strategies.

### 5 Alerts and SRE

#### 5.1. Rules and Thresholds for Triggering Alerts

Below are the thresholds for the three critical metrics proposed earlier. These thresholds are based on service levels that ensure optimal performance without impacting user experience or system integrity.

##### a. **Cloud Functions Latency**

- **Threshold**: 500 ms (average) and 1 second (peak).
- **Alert Rule**:
  - Critical alert if the average latency exceeds 500 ms over a continuous period of 5 minutes.
  - Warning alert if any invocation latency exceeds 1 second.
  
**Rationale**: Latency is critical in systems where rapid response is key to user experience or process continuity. A response time above 500 ms might indicate inefficient BigQuery queries, stress on the function, or general performance issues in the system. The 1-second threshold is for detecting latency "spikes" that could indicate occasional problems.

##### b. **Pub/Sub Error Rate**

- **Threshold**: 1% of failed messages.
- **Alert Rule**:
  - Critical alert if more than 1% of the messages published to Pub/Sub fail to be delivered or processed within a 5-minute period.
  
**Rationale**: Pub/Sub is the central messaging system for communication between components. If more than 1% of messages fail, it indicates a problem that may affect key data transmission between systems, such as data ingestion. This low threshold ensures that problems are detected quickly before impacting data consistency and reliability.

##### c. **BigQuery Query Times**

- **Threshold**: 1 second (average) and 2 seconds (peak).
- **Alert Rule**:
  - Critical alert if the average query latency exceeds 1 second over a 5-minute period.
  - Warning alert if any query exceeds 2 seconds.
  
**Rationale**: Queries to BigQuery are crucial for Cloud Functions' responses. Elevated query times could indicate issues with BigQuery infrastructure, inefficient queries, or data bottlenecks. A latency above 1 second would impact overall application performance.

#### 5.2. SLIs and SLOs

**SLIs (Service Level Indicators)** are key metrics that measure the availability or performance of services. An **SLO (Service Level Objective)** is the target we aim to achieve for those SLIs over a period of time.

##### a. **Cloud Functions Latency**

- **SLI**: **Percentage of Cloud Function invocations with latency under 500 ms**.
- **SLO**: 99% of Cloud Function invocations should have latency under 500 ms over a monthly period.

**Rationale**: The 99% target ensures that most invocations are fast and aligns with the expectation that functions should be nearly instantaneous. I chose this SLI because latency directly affects user experience and overall system performance. A lower SLO (e.g., 95%) might be too permissive with too many failures.

##### b. **Pub/Sub Error Rate**

- **SLI**: **Percentage of Pub/Sub messages published without error**.
- **SLO**: 99.9% of messages should be published without error over a monthly period.

**Rationale**: The system depends on successful message delivery in Pub/Sub for data ingestion and processing. A 99.9% target ensures very high reliability in message delivery, minimizing the risk of data loss. I discarded a metric related to Pub/Sub delivery time, as message success is more critical than latency for this system.

##### c. **BigQuery Availability**

- **SLI**: **Percentage of BigQuery queries completed successfully in under 1 second**.
- **SLO**: 98% of queries should complete successfully in under 1 second over a monthly period.

**Rationale**: BigQuery queries need to be fast for Cloud Functions to respond efficiently. The 98% target ensures that most queries are quick and prevents bottlenecks. A stricter SLO (e.g., 99%) might not be necessary given that BigQuery queries can be more costly depending on complexity, and allowing some latency is reasonable.

#### Why Other Metrics Were Discarded

- **CPU/RAM/DISK Usage**: While these metrics are essential for infrastructure monitoring, they are not directly related to user experience or system performance in terms of latency, message delivery, or query success.

- **Pub/Sub Delivery Times**: Latency in Pub/Sub is less critical in this case, as the most important factor is successful message delivery.

- **Cloud Functions Availability**: Given the system's relatively small scale, Cloud Functions are likely to have high intrinsic availability if properly configured. Instead of focusing on availability, latency is more relevant.

These SLIs/SLOs prioritize end-user experience and data integrity, ensuring that the system operates efficiently and reliably.

---
