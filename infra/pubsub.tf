// Pub/Sub topic "product_sales"
resource "google_pubsub_topic" "product_sales_topic" {
  name    = "product_sales_topic"
  project = var.project_id
  labels = {
    env = var.environment
  }
  message_retention_duration = "86600s" # 1 day
  depends_on                 = [google_project_iam_member.data_engineering_pubsub]
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
  depends_on = [google_project_iam_member.data_engineering_pubsub, google_bigquery_table.product_sales_table]
}