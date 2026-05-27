variable "project_id" {
  type        = string
  description = "Project ID to deploy resources in."
}

variable "region" {
  type = string
}

variable "data_product_name" {
  type = string
  validation {
    condition     = can(regex("[a-z]{1}[-a-z0-9]{3,28}[a-z0-9]{1}", var.data_product_name)) && length(var.data_product_name) <= 63
    error_message = "Google cloud storage bucket name can contain 1-63 characters and dashes."
  }
}

variable "environment" {
  description = "Environment of the deployed project."
  type        = string
  validation {
    condition     = var.environment == "dev" || var.environment == "prd" || var.environment == "pre" || var.environment == "sbx"
    error_message = "The environment must be one of 'dev', 'prd', 'pre', or 'sbx'."
  }
}

variable "domain" {
  type = string
}

variable "envconfig_id" {
  type = string
}

variable "platform_name" {
  type    = string
  default = "cortex"
}

variable "dataset_consumer_config_map" {
  type = map(any)
}

variable "dataset_all" {
  type = list(string)
}

variable "gcs_output_ports" {
  type = list(string)
}

variable "input_port_access" {
  type = list(map(any))
}

variable "secret_names" {
  type = list(string)
}

variable "data_product_metadata" {
  type = map(any)
}

variable "catalogue_map" {
  type = list(map(string))
}

variable "technical_owner" {
  type    = list(string)
  default = []
}
