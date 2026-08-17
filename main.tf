terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}


data "azurerm_client_config" "current" {}

# resource "azurerm_role_assignment" "me_blob" {
#   scope                = azurerm_storage_account.state.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = data.azurerm_client_config.current.object_id

#   lifecycle {
#     ignore_changes = [principal_id]
#   }
# }

variable "location" {
  type    = string
  default = "eastus2"
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "lab" {
  name     = "rg-tfstate-lab"
  location = var.location
}

resource "azurerm_storage_account" "state" {
  name                     = "sttfstatelab${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.lab.name
  location                 = azurerm_resource_group.lab.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  # This is the problem being recreated: reachable from anywhere on the internet.
  public_network_access_enabled = false

  # Recovery net, so a botched cutover later is survivable.
  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "state" {
  name = "tfstate"

  # azurerm < 4.8 uses storage_account_name = azurerm_storage_account.state.name
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

output "storage_account_name" {
  value = azurerm_storage_account.state.name
}

output "resource_group_name" {
  value = azurerm_resource_group.lab.name
}
