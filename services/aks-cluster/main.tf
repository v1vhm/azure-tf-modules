

resource "azurerm_kubernetes_cluster" "example" {
  name                = var.name
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.name

  default_node_pool {
    name                = "${var.name}"
    node_count          = var.desired_size
    vm_size             = "Standard_D2_v2"
    enable_auto_scaling = true
    max_count           = var.max_size
    min_count           = var.min_size
  }

  identity {
    type = "SystemAssigned"
  }
}

