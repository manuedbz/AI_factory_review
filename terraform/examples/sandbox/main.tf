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

variable "dns_subscription_id" {
  type        = string
  description = "Souscription portant la zone DNS (IT-Management). Optionnel tant que dns n'est pas activé."
  default     = null
}

variable "tenant_id" {
  type = string
}

provider "azurerm" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  features {}
}

provider "azurerm" {
  alias           = "dns"
  tenant_id       = var.tenant_id
  subscription_id = coalesce(var.dns_subscription_id, var.subscription_id)
  features {}
}

resource "azurerm_resource_group" "this" {
  name     = "rg-ai-factory-sandbox"
  location = "francecentral"
  tags     = { CreatedBy = "terraform" }
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-ai-factory-sandbox"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Prérequis partagé par toutes les apps
resource "azurerm_container_app_environment" "this" {
  name                       = "cae-ai-factory-sandbox"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
}

module "app" {
  source = "../../modules/app"
  providers = {
    azurerm     = azurerm
    azurerm.dns = azurerm.dns
  }

  name                         = "report"
  env                          = "dev"
  rg_name                      = azurerm_resource_group.this.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  external_ingress             = true

  # dns = { zone_name = "<zone privée>", rg_name = "rg-dns" }  # à activer quand la zone est choisie
}

output "app" {
  value = {
    fqdn          = module.app.fqdn
    key_vault_uri = module.app.key_vault_uri
  }
}
