# Amorçage : Key Vault propre à la factory (SandBox).
# Se déploie une fois, avec la session `az login`. State local (non versionné).
terraform {
  required_version = ">= 1.8.1"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

variable "subscription_id" {
  type        = string
  description = "Souscription SandBox."
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "core" {
  name     = "rg-ai-factory-core"
  location = "francecentral"
  tags     = { CreatedBy = "terraform", Project = "ai-factory" }
}

resource "azurerm_key_vault" "factory" {
  name                = "kv-frc-sbx-aifactory"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled    = true
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  public_network_access_enabled = true # lecture depuis les postes de dev (sandbox)

  tags = { CreatedBy = "terraform", Project = "ai-factory" }
}

# L'utilisateur qui déploie peut gérer les secrets
resource "azurerm_role_assignment" "deployer" {
  scope                = azurerm_key_vault.factory.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

output "key_vault_name" {
  value = azurerm_key_vault.factory.name
}
