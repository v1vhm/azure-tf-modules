
variable "environment" {
  description = "The environment being deployed into"
  type        = string
}

variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  type        = string
}

variable "db_remote_state_resource_group" {
  description = "The name of the resource group that contains the remote state storage account"
  type        = string
}

variable "db_remote_state_storage_account" {
  description = "The name of the storage account for the database's remote state"
  type        = string
}

variable "db_remote_state_key" {
  description = "The path for the database's remote state"
  type        = string
}

variable "custom_tags" {
  description = "Custom tags to set on the instances in the scale set"
  type        = map(string)
  default     = {}
}

variable "enable_autoscaling" {
  description = "If set to true, enable autoscaling"
  type        = bool
}

variable "server_text" {
  description = "The text the web server should return"
  type        = string
  default     = "Hello, world!"
}

variable "app_version" {
  description = "The current version of the app"
  type        = string
}