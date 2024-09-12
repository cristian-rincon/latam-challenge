// Data sources for the Cloud Functions source code

data "archive_file" "ingestion_source_code_archive" {
  type        = "zip"
  source_dir  = "../product_sales/ingestion"
  output_path = "/tmp/ingestion.zip"
}

data "archive_file" "fetch_data_source_code_archive" {
  type        = "zip"
  source_dir  = "../product_sales/fetch"
  output_path = "/tmp/fetch.zip"
}


// Storage bucket for the Cloud Functions source code
resource "google_storage_bucket" "staging_bucket" {
  name     = "${var.project_id}-staging"
  project  = var.project_id
  location = var.region
}

// Storage bucket objects for the Cloud Functions source code
resource "google_storage_bucket_object" "ingest_data_source_object" {
  name   = "ingestion.zip"
  bucket = google_storage_bucket.staging_bucket.name
  source = data.archive_file.ingestion_source_code_archive.output_path
}

resource "google_storage_bucket_object" "fetch_data_source_object" {
  name   = "fetch.zip"
  bucket = google_storage_bucket.staging_bucket.name
  source = data.archive_file.fetch_data_source_code_archive.output_path
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

// Cloud Function "fetch_data" to fetch product sales data

resource "google_cloudfunctions2_function" "fn_fetch_data" {
  name        = "fetch-data"
  location    = var.region
  description = "Fetch product sales data"

  build_config {
    runtime     = "python39"
    entry_point = "fetch_data" # Set the entry point
    source {
      storage_source {
        bucket = google_storage_bucket.staging_bucket.name
        object = google_storage_bucket_object.fetch_data_source_object.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 300
    environment_variables = {
      GCP_PROJECT      = var.project_id
      BIGQUERY_DATASET = google_bigquery_dataset.ecommerce_analytics.dataset_id
      BIGQUERY_TABLE   = google_bigquery_table.product_sales_table.table_id
    }
    service_account_email = google_service_account.data_engineering.email
  }
}