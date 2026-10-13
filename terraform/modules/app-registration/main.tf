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

variable "name" {
  type        = string
  description = "Nom fonctionnel de l'app (ex: report)."
}

variable "github_repository" {
  type        = string
  description = "Repo GitHub autorisé à se connecter, au format owner/repo."

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository: format owner/repo."
  }
}

variable "environments" {
  type        = set(string)
  description = "Environnements GitHub autorisés (un credential fédéré chacun)."
  default     = ["dev", "prod"]
}

variable "acr_id" {
  type        = string
  description = "Id de l'ACR où le pipeline pousse les images (rôle AcrPush)."
}

variable "secrets_kv_id" {
  type        = string
  description = "Key Vault de la factory que le pipeline lit (jetons npm...) : rôle Key Vault Secrets User. null = aucun."
  default     = null
}

variable "deploy_scope_ids" {
  type        = list(string)
  description = "Ressources que le pipeline peut déployer (rôle Contributor), ex: ids des Container Apps."
  default     = []
}

data "azuread_client_config" "current" {}

resource "azuread_application" "this" {
  display_name = "app-${var.name}"
  owners       = [data.azuread_client_config.current.object_id]
  notes        = "Créé par AI_factory (Terraform). Identité du pipeline GitHub de ${var.github_repository}."
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application.this.client_id
  owners    = [data.azuread_client_config.current.object_id]
}

# Connexion GitHub Actions -> Azure sans secret (OIDC)
resource "azuread_application_federated_identity_credential" "github" {
  for_each = var.environments

  application_id = azuread_application.this.id
  display_name   = "github-${each.key}"
  description    = "GitHub Actions, environnement ${each.key}"
  issuer         = "https://token.actions.githubusercontent.com"
  audiences      = ["api://AzureADTokenExchange"]
  subject        = "repo:${var.github_repository}:environment:${each.key}"
}

resource "azurerm_role_assignment" "acr_push" {
  scope                = var.acr_id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.this.object_id
}

resource "azurerm_role_assignment" "read_factory_kv" {
  count = var.secrets_kv_id != null ? 1 : 0

  scope                = var.secrets_kv_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.this.object_id
}

resource "azurerm_role_assignment" "deploy" {
  count = length(var.deploy_scope_ids)

  scope                = var.deploy_scope_ids[count.index]
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.this.object_id
}

output "client_id" {
  description = "À stocker dans la variable AZURE_CLIENT_ID de l'environnement GitHub."
  value       = azuread_application.this.client_id
}

output "object_id" {
  value = azuread_service_principal.this.object_id
}
