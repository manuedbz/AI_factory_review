terraform {
  required_version = ">= 1.8.1"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

variable "name" {
  type        = string
  description = "Nom du registry (5 à 50 caractères alphanumériques, unique dans Azure)."

  validation {
    condition     = can(regex("^[a-z0-9]{5,50}$", var.name))
    error_message = "name: 5 à 50 caractères, minuscules et chiffres uniquement."
  }
}

variable "rg_name" {
  type = string
}

variable "location" {
  type    = string
  default = "francecentral"
}

variable "sku" {
  type        = string
  description = "Basic suffit en sandbox. Premium est requis pour un private endpoint (cas du repo azure)."
  default     = "Basic"
}

variable "public_access" {
  type        = bool
  description = "false requiert le SKU Premium et un private endpoint."
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "azurerm_container_registry" "this" {
  name                = var.name
  resource_group_name = var.rg_name
  location            = var.location
  sku                 = var.sku

  admin_enabled                 = false # authentification par identité uniquement
  public_network_access_enabled = var.public_access

  tags = var.tags

  lifecycle {
    ignore_changes = [tags["createdAt"], tags["updatedAt"], tags["env"], tags["Env"]]
  }
}

output "id" {
  value = azurerm_container_registry.this.id
}

output "name" {
  value = azurerm_container_registry.this.name
}

output "login_server" {
  value = azurerm_container_registry.this.login_server
}
