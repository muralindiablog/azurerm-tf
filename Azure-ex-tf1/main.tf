# Variables

variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "vnet_cidr_range" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_prefixes" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "subnets_names" {
  type    = list(string)
  default = ["web", "database"]
}

# Provider
provider "azurerm" {
  skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
}

# Resources

module "vnet-main" {
  source              = "Azure/vnet/azurerm"
  resource_group_name = var.resource_group_name
  location            = var.location
  vnet_name           = var.resource_group_name
  address_space       = var.vnet_cidr_range
  subnet_prefixes     = var.subnet_prefixes
  subnets_names       = var.subnets_names
  nsg                 = {}

  tags = {
    environment = "dev"
    costcenter  = "it"
  }
}

# output

output "vnet_id" {
  value = module.vnet-main.vnet_id
}

