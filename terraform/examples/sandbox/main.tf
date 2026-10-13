terraform {
  required_version = ">= 1.8.1"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
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

provider "azuread" {
  tenant_id = var.tenant_id
}

resource "azurerm_resource_group" "this" {
  name     = "rg-ai-factory-sandbox"
  location = "francecentral"
  tags     = { CreatedBy = "terraform" }

  lifecycle {
    ignore_changes = [tags["createdAt"], tags["updatedAt"], tags["env"], tags["Env"]]
  }
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-ai-factory-sandbox"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  lifecycle {
    ignore_changes = [tags["createdAt"], tags["updatedAt"], tags["env"], tags["Env"]]
  }
}

# Prérequis partagé par toutes les apps
resource "azurerm_container_app_environment" "this" {
  name                       = "cae-ai-factory-sandbox"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  lifecycle {
    ignore_changes = [tags["createdAt"], tags["updatedAt"], tags["env"], tags["Env"]]
  }
}

# Registry partagé par toutes les apps
module "acr" {
  source = "../../modules/acr"

  name    = "acraifactorysbx"
  rg_name = azurerm_resource_group.this.name
  tags    = { CreatedBy = "terraform" }
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
  acr = {
    id           = module.acr.id
    login_server = module.acr.login_server
  }

  # dns = { zone_name = "<zone privée>", rg_name = "rg-dns" }  # à activer quand la zone est choisie
}

# Identité du pipeline GitHub (OIDC, sans secret)
module "app_registration" {
  source = "../../modules/app-registration"

  name              = "report"
  github_repository = "manuedbz/report-demo" # repo fictif : seul le nom compte pour la confiance OIDC
  environments      = ["dev"]
  acr_id            = module.acr.id
  deploy_scope_ids  = [module.app.id]
}

output "app" {
  value = {
    fqdn          = module.app.fqdn
    key_vault_uri = module.app.key_vault_uri
    acr           = module.acr.login_server
    client_id     = module.app_registration.client_id
    name          = "report-dev"
    acr_name      = "acraifactorysbx"
    rg_name       = azurerm_resource_group.this.name
  }
}
