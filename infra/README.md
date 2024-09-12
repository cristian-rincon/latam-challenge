## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | 6.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.6.0 |
| <a name="provider_google"></a> [google](#provider\_google) | 6.2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_bigquery_dataset.ecommerce_analytics](https://registry.terraform.io/providers/hashicorp/google/6.2.0/docs/resources/bigquery_dataset) | resource |
| [google_bigquery_table.product_sales_table](https://registry.terraform.io/providers/hashicorp/google/6.2.0/docs/resources/bigquery_table) | resource |
| [google_cloudfunctions2_function.fn_fetch_data](https://registry.terraform.io/providers/hashicorp/google/6.2.0/docs/resources/cloudfunctions2_function) | resource |
| [google_cloudfunctions2_function.fn_ingest_data](https://registry.terraform.io/providers/hashicorp/google/6.2.0/docs/resources/cloudfunctions2_function) | resource |
| [google_project_iam_member.data_engineering_bigquery_data_editor](https://registry.terraform.io/providers/hashicorp/google/6.2.0/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.data_engineering_bigquery_user](https://registry.terraform.io/providers/hashicorp/google/6.2.0/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.data_engineering_cloudfunctions](https://registry.terraform.io/providers/hashicorp/google/6.2.0/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.data_engineering_pubsub](https://registry.terraform.io/providers/hashicorp/google/6.2.0/docs/resources/project_iam_member) | resource |
| [google_pubsub_subscription.product_sales_subscription](https://registry.terraform.io/providers/hashicorp/google/6.2.0/docs/resources/pubsub_subscription) | resource |
| [google_pubsub_topic.product_sales_topic](https://registry.terraform.io/providers/hashicorp/google/6.2.0/docs/resources/pubsub_topic) | resource |
| [google_service_account.data_engineering](https://registry.terraform.io/providers/hashicorp/google/6.2.0/docs/resources/service_account) | resource |
| [google_storage_bucket.staging_bucket](https://registry.terraform.io/providers/hashicorp/google/6.2.0/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_object.fetch_data_source_object](https://registry.terraform.io/providers/hashicorp/google/6.2.0/docs/resources/storage_bucket_object) | resource |
| [google_storage_bucket_object.ingest_data_source_object](https://registry.terraform.io/providers/hashicorp/google/6.2.0/docs/resources/storage_bucket_object) | resource |
| [archive_file.fetch_data_source_code_archive](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.ingestion_source_code_archive](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | The environment | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project ID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecommerce_analytics_dataset_id"></a> [ecommerce\_analytics\_dataset\_id](#output\_ecommerce\_analytics\_dataset\_id) | n/a |
| <a name="output_fn_ingest_data_url"></a> [fn\_ingest\_data\_url](#output\_fn\_ingest\_data\_url) | n/a |
| <a name="output_product_sales_subscription_name"></a> [product\_sales\_subscription\_name](#output\_product\_sales\_subscription\_name) | n/a |
| <a name="output_product_sales_table_id"></a> [product\_sales\_table\_id](#output\_product\_sales\_table\_id) | n/a |
| <a name="output_product_sales_topic_name"></a> [product\_sales\_topic\_name](#output\_product\_sales\_topic\_name) | n/a |
