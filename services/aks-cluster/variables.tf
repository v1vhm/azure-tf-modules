variable "name" {
  description = "The name to use for the AKS cluster"
  type        = string
}

variable "min_size" {
  description = "Minimum numner of nodes to have in the AKS cluster"
  type        = number
}

variable "max_size" {
  description = "Maximum number of nodes to have in the AKS cluster"
  type        = number
}

variable "desired_size" {
    description = "Desired number of nodes to have in the AKS cluster"
    type        = number
}

variable "resource_group_name" {
  description = "Resource group for the cluster"
  type        = string
}

variable "resource_group_location" {
  description = "Location of the resource group"
  type        = string
  
}