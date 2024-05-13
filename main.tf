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

  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet" "azuretf-subnet" {
  name                 = "azuretf-subnet1"
  resource_group_name  = azurerm_resource_group.azuretf-rg.name
  virtual_network_name = azurerm_virtual_network.azuretf-vn.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_network_security_rule" "azuretf-gs-rule" {
  name                        = "azuretf-sg-rule1"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.azuretf-rg.name
  network_security_group_name = azurerm_network_security_group.azuretf-sg.name
}

resource "azurerm_subnet_network_security_group_association" "azuretf-sga" {
  subnet_id                 = azurerm_subnet.azuretf-subnet.id
  network_security_group_id = azurerm_network_security_group.azuretf-sg.id
}

resource "azurerm_public_ip" "azuretf-ip" {
  name                = "azuretf-ip"
  resource_group_name = azurerm_resource_group.azuretf-rg.name
  location            = azurerm_resource_group.azuretf-rg.location
  allocation_method   = "Static"

  tags = {
    environment = "Dev"
  }
}