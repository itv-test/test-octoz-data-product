locals {
  root_config_path  = "../config"
  config            = yamldecode(file("${local.root_config_path}/config.yml"))
  region            = lookup(local.config, "region", "europe-west2")
  domain            = local.config["domain"]
  data_product_name = local.config["data-product-name"]
  dataset_all       = [for dataset in local.config["datasets"] : dataset.name]
  catalogue_map     = local.config["datasets"]
  gcs_output_ports  = can(local.config["gcs-output-ports"]) ? local.config["gcs-output-ports"] : []
  environment_vars  = read_terragrunt_config("env.hcl")
  project_id        = local.environment_vars.locals.project_id
  environment       = local.environment_vars.locals.environment
  envconfig_id      = "itv-data-envconfig-${local.environment}"
  secret_names      = can(local.config["secret-names"]) ? local.config["secret-names"] : []
  data_product_metadata = {
    data_product_owner = replace(replace(local.config["data-product-owner"], "@itv.com", ""), ".", "")
    data_product_name  = local.data_product_name
    domain             = local.domain
  }
  technical_owner         = [for email in local.config["technical-owner"] : "user:${email}"]
  config_data_access_path = "../config/${local.environment}"

  data_access_config = can(yamldecode(file("${local.config_data_access_path}/data_access.yml"))) ? (
    yamldecode(file("${local.config_data_access_path}/data_access.yml"))
  ) : {
    dataset = [],
    input-port-access = []
  }
  # Decode only the 'dataset' part from the YAML
  dataset_consumer_config = can(local.data_access_config["dataset"]) ? tolist(local.data_access_config["dataset"]) : []


  # Map to extract relevant details from the decoded dataset
  dataset_consumer_config_map = length(local.dataset_consumer_config) > 0 ? {
    for dataset in local.dataset_consumer_config :
    dataset.name => [
      for table in dataset.tables : {
        table_name = table.name
        consumers  = table.consumers
        gcs_path   = table.gcs-path
      }
    ]
  } : {} # Return an empty map if dataset is missing or empty

  # Input port write permissions extraction
  input_port_access = can(local.data_access_config["input-port-access"]) ? local.data_access_config["input-port-access"] : []
}

remote_state {
  backend = "gcs"
  config = {
    skip_bucket_creation = true
    bucket                    = "itv-data-platform-tf-data-products-${local.environment}"
    prefix                    = "${local.domain}/${local.data_product_name}"
    project                   = "itv-${local.environment}-envconfig"
    location                  = local.region
    enable_bucket_policy_only = true
    gcs_bucket_labels = {
      "deployment_tool" = "terraform"
    }
    impersonate_service_account = "tf-${local.data_product_name}@itv-data-envconfig-${local.environment}.iam.gserviceaccount.com"
  }
}


generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "gcs" {}
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.11.1"
    }
  }
}
provider "google" {
  default_labels = {
      deployment_tool = "terraform",
      managed_by      = "platform"
      #Label TF/provider version.
  }
  impersonate_service_account = "tf-${local.data_product_name}@itv-data-envconfig-${local.environment}.iam.gserviceaccount.com"
}
provider "google-beta" {
  default_labels = {
      deployment_tool = "terraform",
      managed_by      = "platform"
      #Label TF/provider version.
  }
  impersonate_service_account = "tf-${local.data_product_name}@itv-data-envconfig-${local.environment}.iam.gserviceaccount.com"
}
EOF
}

inputs = merge(
  local.environment_vars.locals,
  {
    region             = local.region
    data_product_name      = local.data_product_name
    domain       = local.domain
    envconfig_id = local.envconfig_id
    dataset_consumer_config_map       = local.dataset_consumer_config_map
    dataset_all = local.dataset_all
    gcs_output_ports = local.gcs_output_ports
    secret_names = local.secret_names
    input_port_access = local.input_port_access
    data_product_metadata = local.data_product_metadata
    catalogue_map = local.catalogue_map
    technical_owner = local.technical_owner
  },
)