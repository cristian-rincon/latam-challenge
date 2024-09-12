// Bigquery dataset "ecommerce_analytics"
resource "google_bigquery_dataset" "ecommerce_analytics" {
  dataset_id                  = "ecommerce_analytics"
  project                     = var.project_id
  location                    = var.region
  default_table_expiration_ms = "2592000000" # 30 days in milliseconds
  labels = {
    env = var.environment
  }
}

# Bigquery table "ecommerce_analytics.sales"
resource "google_bigquery_table" "product_sales_table" {
  dataset_id          = google_bigquery_dataset.ecommerce_analytics.dataset_id
  table_id            = "product_sales"
  deletion_protection = true
  time_partitioning {
    type = "DAY"
  }

  // Bigquery table schema
  // product_id: STRING
  // product_name: STRING
  // category: STRING
  // unit_price: FLOAT
  // supplier: STRING

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
}