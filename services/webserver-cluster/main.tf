terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.73.0"
    }
  }
}

data "terraform_remote_state" "database" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.db_remote_state_resource_group
    storage_account_name = var.db_remote_state_storage_account
    container_name       = "tfstate"
    key                  = var.db_remote_state_key
    use_azuread_auth     = true
  }
}

locals {
  server_port = 8080
  tags = {
    Name = var.cluster_name
  }
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = "v1vhm-${var.cluster_name}-${var.environment}-weu-001"
  location = "West Europe"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "example" {
  name                = "${var.cluster_name}-network-${var.environment}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "example" {
  name                = "${var.cluster_name}-nic-${var.environment}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "${var.cluster_name}-nsg-${var.environment}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "${var.cluster_name}-rule-${var.environment}"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = local.server_port
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

resource "azurerm_linux_virtual_machine_scale_set" "example" {
  name                            = "${var.cluster_name}-vss-${var.environment}"
  resource_group_name             = azurerm_resource_group.example.name
  location                        = azurerm_resource_group.example.location
  instances                       = 1
  sku                             = "Standard_F2"
  admin_username                  = "adminuser"
  admin_password                  = "hCU9dPL7zxZGzfh2CG5m"
  disable_password_authentication = false
  custom_data = base64encode(templatefile("${path.module}/custom-data.sh", {
    server_port = local.server_port
    db_address  = data.terraform_remote_state.database.outputs.address
  }))
  tags = merge(local.tags, var.custom_tags)

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  network_interface {
    name    = "example"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.example.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.example.id]
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Since these can change via auto-scaling outside of Terraform,
  # let's ignore any changes to the number of instances
  lifecycle {
    ignore_changes = [instances]
  }

}

resource "azurerm_public_ip" "example" {
  name                = "${var.cluster_name}-pip-${var.environment}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "example" {
  name                = "${var.cluster_name}-lb-${var.environment}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.example.id
  }


}

resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "acctestpool"
}


resource "azurerm_lb_probe" "example2" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "http-running-probe"
  port            = local.server_port
}

resource "azurerm_lb_rule" "example" {
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "${var.cluster_name}-http-rule-${var.environment}"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 8080
  frontend_ip_configuration_name = azurerm_lb.example.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.example.id]
  probe_id                       = azurerm_lb_probe.example2.id
}