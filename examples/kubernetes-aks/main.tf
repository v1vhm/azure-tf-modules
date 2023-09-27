terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.73.0"
    }
  }

    backend "azurerm" {
      resource_group_name  = "v1vhm-rg-tfstate-prod-weu-001"
      storage_account_name = "v1vhmsttfstateprodweu001"
      container_name       = "tfstate"
      key                  = "stage/examples/kubernetes-aks/terraform.tfstate"
      use_azuread_auth     = true
    }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  skip_provider_registration = true # This is only required when t$he User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {
    
  }
}

# Create a resource group
resource "azurerm_resource_group" "aks" {
  name     = "v1vhm-aks-stage-weu-001"
  location = "West Europe"
}

module "aks_cluster" {
    source = "../../services/aks-cluster"

    name           = "v1vhmaks1"
    min_size       = 1
    max_size       = 2
    desired_size   = 1

    resource_group_location = azurerm_resource_group.aks.location
    resource_group_name     = azurerm_resource_group.aks.name
}

provider "kubernetes" {
    host                   = module.aks_cluster.cluster_host
    cluster_ca_certificate = base64decode(module.aks_cluster.cluster_ca_certificate)
    client_certificate     = base64decode(module.aks_cluster.client_certificate)
    client_key             = base64decode(module.aks_cluster.client_key)
}

module "simple_webapp" {
  source         = "../../services/k8s-app"
  name           = "simple-webapp"
  image          = "training/webapp"
  replicas       = 2
  container_port = 5000

  environment_variables = {
    PROVIDER = "Terraform"
  }

  depends_on = [ module.aks_cluster ]
}

output "service_endpoint" {
  value       = module.simple_webapp.service_endpoint
  description = "The K8S service endpoint"
}