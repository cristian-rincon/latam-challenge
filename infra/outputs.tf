output "ecommerce_analytics_dataset_id" {
  value = google_bigquery_dataset.ecommerce_analytics.dataset_id
}

output "product_sales_table_id" {
  value = google_bigquery_table.product_sales_table.table_id
}

output "product_sales_topic_name" {
  value = google_pubsub_topic.product_sales_topic.name
}

output "product_sales_subscription_name" {
  value = google_pubsub_subscription.product_sales_subscription.name
}

output "fn_ingest_data_url" {
  value = google_cloudfunctions2_function.fn_ingest_data.url
}