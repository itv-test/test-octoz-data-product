locals {
  data_product_service_account = "ex-${var.data_product_name}@itv-data-${var.domain}-dom-${var.environment}.iam.gserviceaccount.com"
  dataset_consumer_config_map  = var.dataset_consumer_config_map
  catalogue_map                = var.catalogue_map
}

module "external_connection" {
  source                       = "github.com/ITV/tf-gcp-data-bigquery//external_connection/?ref=v2.0.0"
  project_id                   = var.project_id
  environment                  = var.environment
  data_product_name            = var.data_product_name
  region                       = var.region
  data_product_service_account = local.data_product_service_account
}

module "bucket" {
  source                       = "github.com/ITV/tf-gcp-data-bucket?ref=v2.1.0"
  project_id                   = var.project_id
  environment                  = var.environment
  data_product_name            = var.data_product_name
  region                       = var.region
  data_product_service_account = local.data_product_service_account
  external_connection_id       = [module.external_connection.connection_id]
  output_ports                 = var.gcs_output_ports
  dataset_consumers_map        = local.dataset_consumer_config_map
  depends_on                   = [module.external_connection]
  input_port_access            = var.input_port_access
  data_product_metadata        = var.data_product_metadata
}

module "big_query_dataset" {
  source                       = "github.com/ITV/tf-gcp-data-bigquery//dataset/?ref=v2.0.0"
  project_id                   = var.project_id
  environment                  = var.environment
  data_product_name            = var.data_product_name
  region                       = var.region
  data_product_service_account = local.data_product_service_account
  datasets                     = var.dataset_all
  data_product_metadata        = var.data_product_metadata
  depends_on                   = [module.bucket]
}

# the secret values need to be populated manually after the secrets created
module "secrets" {
  for_each                     = toset(var.secret_names)
  source                       = "github.com/ITV/tf-gcp-data-secrets?ref=v1.0.0"
  secret_name                  = each.value
  project_id                   = var.project_id
  region                       = var.region
  data_product_service_account = "serviceAccount:${local.data_product_service_account}"
  data_product_name            = var.data_product_name
  secret_version_managers      = var.technical_owner
}