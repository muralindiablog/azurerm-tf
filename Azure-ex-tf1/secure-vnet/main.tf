# variables

variable "sec_resource_group_name" {
    type = string
    default = "security"
}

variable "location" {
    type = string
    default = "eastus"
}

variable "vnet_cidr_range" {
    type = list(string)
    default = ["10.1.0.0/16"]

}

variable "sec_subnet_prefixes" {
    type = list(string)
    default = ["10.1.0.0/24", "10.1.1.0/24"]
}

variable "sec_subnet_names" {
    type = list(string)
    default = ["siem","inspect"]
}

# Data

data "azurerm_subscription" "current" {}

# providers are empty here as we used azure login 

provider "azurerm" {
  skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
 # alias = "security"
}

# terraform {
#     required_providers {
#         azurerm = {
#             source = "hashicorp/azurerm"
#             version = "4.0.0"
#         }
#     }
# }

provider "azuread" {}

# Resources

# Network

# creation of an azure vnet, service principal in azuread and assign a role on the security subscription

resource "azurerm_resource_group" "sec" {
    name = var.sec_resource_group_name
    location = var.location
    tags = {
        environment = "security"
    }
}

module "vnet" {
    # providers = {
    #      azurerm = azurerm.security
    #      version = "< 4.0.0"
    #  }
  source              = "Azure/vnet/azurerm"
  use_for_each        = true
  resource_group_name = var.sec_resource_group_name
  vnet_location       = var.location
  vnet_name           = var.sec_resource_group_name
  address_space       = var.vnet_cidr_range
  subnet_prefixes     = var.sec_subnet_prefixes
  subnet_names        = var.sec_subnet_names
  nsg_ids             = {}

  tags = {
    environment = "security"
    costcenter  = "it-security"
  }
}

# Azure AD service principal

resource "random_password" "vnet_peering" {
    length = 16
    special = true
}

resource "azuread_application" "vnet_peering" {
    display_name = "vnet-peer"
}

resource "azuread_service_principal" "vnet_peering" {
    application_id = azuread_application.vnet_peering.application_id
}

resource "azuread_service_principal_password" "vnet_peering" {
    service_principal_id = azuread_service_principal.vnet_peering.id 
    #value = random_password.vnet_peering.result 
    end_date_relative = "17520h"
}

# service principal above , role in security subscription and assing to service principal

resource "azurerm_role_definition" "vnet-peering" {
    name = "allow-vnet-peering"
    scope = data.azurerm_subscription.current.id

# https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-manage-peering?tabs=peering-portal
    permissions {
        actions = ["Microsoft.Network/virtualNetworks/virtualNetworkPeerings/Write", 
        "Microsoft.Network/virtualNetworks/peer/action", 
        "Microsoft.ClassicNetwork/virtualNetworks/peer/action",
        "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/delete"]
    }

    assignable_scopes = [
        data.azurerm_subscription.current.id,
    ]
}
 
# Assign the role above to service principal

resource "azurerm_role_assignment" "vnet" {
    scope = module.vnet.vnet_id
    role_definition_id = azurerm_role_definition.vnet-peering.id
    principal_id = azuread_service_principal.vnet_peering.id
}

#provisioners

resource "null_resource" "post-config" {
    depends_on = [azurerm_role_assignment.vnet]

    provisioner "local-exec" {
        command = <<EOT
        echo "export TF_VAR_sec_vnet_id=${module.vnet.vnet_id}" >> next-step.txt
        echo "export TF_VAR_sec_vnet_name=${module.vnet.vnet_name}" >> next-step.txt
        echo "export TF_VAR_sec_sub_id=${data.azurerm_subscription.current.subscription_id}" >> next-step.txt
        echo "export TF_VAR_sec_client_id=${azuread_service_principal.vnet_peering.application_id}" >> next-step.txt
        echo "export TF_Var_sec_principal_id=${azuread_service_principal.vnet_peering.id}" >> next-step.txt
        echo "export TF_VAR_sec_client_secret=${random_password.vnet_peering.result}" >> next-step.txt
        echo "export TF_VAR_sec_resource_group=${azurerm_resource_group.sec.name}" >> next-step.txt
        EOT
    }
}

# Output

output "vnet_id" {
    value = module.vnet.vnet_id
}

output "vnet_name" {
    value = module.vnet.vnet_name 
}

output "service_principal_client_id" {
    value = azuread_service_principal.vnet_peering.id 
}

output "service_principal_client_secret" {
    value = random_password.vnet_peering.result
    sensitive = true
}

output "resource_group_name" {
    value = azurerm_resource_group.sec.name 
}

