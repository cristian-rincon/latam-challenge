// Pub/Sub topic "product_sales"
resource "google_pubsub_topic" "product_sales_topic" {
  name    = "product_sales_topic"
  project = var.project_id
  labels = {
    env = var.environment
  }
  message_retention_duration = "86600s" # 1 day
}

// Pub/Sub subscription "product_sales"
resource "google_pubsub_subscription" "product_sales_subscription" {
  name    = "product_sales_subscription"
  topic   = google_pubsub_topic.product_sales_topic.name
  project = var.project_id
  labels = {
    env = var.environment
  }

  bigquery_config {
    table                 = "${var.project_id}.${google_bigquery_dataset.ecommerce_analytics.dataset_id}.${google_bigquery_table.product_sales_table.table_id}"
    service_account_email = google_service_account.data_engineering.email
    use_table_schema      = true
  }
  depends_on = [google_bigquery_table.product_sales_table]
}


// Storage bucket for the Cloud Function source code
resource "google_storage_bucket" "staging_bucket" {
  name     = "${var.project_id}-staging"
  project  = var.project_id
  location = var.region
}

data "archive_file" "ingestion_source_code_archive" {
  type        = "zip"
  source_dir  = "../product_sales/ingestion"
  output_path = "/tmp/ingestion.zip"
}

// Storage bucket object for the Cloud Function source code
resource "google_storage_bucket_object" "ingest_data_source_object" {
  name   = "ingestion.zip"
  bucket = google_storage_bucket.staging_bucket.name
  source = data.archive_file.ingestion_source_code_archive.output_path
}

// Cloud Function "product_sales" to ingest product sales data

resource "google_cloudfunctions2_function" "fn_ingest_data" {
  name        = "ingest-data"
  location    = var.region
  description = "Ingest product sales data"

  build_config {
    runtime     = "python39"
    entry_point = "ingest_data" # Set the entry point
    source {
      storage_source {
        bucket = google_storage_bucket.staging_bucket.name
        object = google_storage_bucket_object.ingest_data_source_object.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 300
    environment_variables = {
      BIGQUERY_DATASET = google_bigquery_dataset.ecommerce_analytics.dataset_id
      BIGQUERY_TABLE   = google_bigquery_table.product_sales_table.table_id
      GCP_PROJECT      = var.project_id
      PUBSUB_TOPIC     = google_pubsub_topic.product_sales_topic.name
    }
    service_account_email = google_service_account.data_engineering.email
  }
}

// Grant the Cloud Function service account the necessary permissions
