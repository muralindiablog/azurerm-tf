terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
}

resource "azurerm_resource_group" "azuretf-rg" {
  name     = "azuretf-resources"
  location = "East US"
  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_security_group" "azuretf-sg" {
  name                = "azuretf-sg"
  location            = azurerm_resource_group.azuretf-rg.location
  resource_group_name = azurerm_resource_group.azuretf-rg.name
}

resource "azurerm_virtual_network" "azuretf-vn" {
  name                = "azuretf-network"
  location            = azurerm_resource_group.azuretf-rg.location
  resource_group_name = azurerm_resource_group.azuretf-rg.name
  address_space       = ["10.0.0.0/16"]

  subnet {
    name           = "subnet1"
    address_prefix = "10.0.1.0/24"
  }

  subnet {
    name           = "subnet2"
    address_prefix = "10.0.2.0/24"
    security_group = azurerm_network_security_group.azuretf-sg.id
  }


  tags = {
    environment = "dev"
  }
}

