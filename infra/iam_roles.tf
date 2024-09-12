// Service account for the resources
resource "google_service_account" "data_engineering" {
  account_id   = "data-engineering"
  display_name = "Data Engineering Service Account"
  project      = var.project_id
}

// Grant the service account the necessary roles to use pub/sub, cloud functions and bigquery
resource "google_project_iam_member" "data_engineering_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.editor"
  member  = "serviceAccount:${google_service_account.data_engineering.email}"
}

resource "google_project_iam_member" "data_engineering_bigquery_user" {
  project = var.project_id
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${google_service_account.data_engineering.email}"
}
resource "google_project_iam_member" "data_engineering_bigquery_data_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.data_engineering.email}"
}

resource "google_project_iam_member" "data_engineering_cloudfunctions" {
  project = var.project_id
  role    = "roles/cloudfunctions.developer"
  member  = "serviceAccount:${google_service_account.data_engineering.email}"
}

