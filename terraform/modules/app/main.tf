data "azurerm_client_config" "current" {}

locals {
  app_name = "${var.name}-${var.env}"
  tags     = merge({ CreatedBy = "terraform", App = var.name, Env = var.env }, var.tags)
}

# ---------------------------------------------------------------
# Key Vault (nommage et options alignés sur le repo azure)
# ---------------------------------------------------------------
resource "azurerm_key_vault" "this" {
  name                = "kv-frc-${var.env}-${var.name}"
  location            = var.location
  resource_group_name = var.rg_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled    = true
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  public_network_access_enabled = var.kv_public_access

  tags = local.tags

  lifecycle {
    ignore_changes = [tags["createdAt"], tags["updatedAt"], tags["env"], tags["Env"]]
  }
}

# ---------------------------------------------------------------
# Container App
# ---------------------------------------------------------------
resource "azurerm_container_app" "this" {
  name                         = local.app_name
  resource_group_name          = var.rg_name
  container_app_environment_id = var.container_app_environment_id
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = var.name
      image  = var.image
      cpu    = var.cpu
      memory = var.memory

      env {
        name  = "APP_ENV"
        value = var.env
      }
      env {
        name  = "KEY_VAULT_URI"
        value = azurerm_key_vault.this.vault_uri
      }
    }
  }

  ingress {
    external_enabled = var.external_ingress
    target_port      = var.target_port

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = local.tags

  lifecycle {
    # Image : mise à jour ensuite par le pipeline de déploiement. Tags : ajoutés par les policies Azure
    ignore_changes = [template[0].container[0].image, tags["createdAt"], tags["updatedAt"], tags["env"], tags["Env"]]
  }
}

# L'app peut lire les secrets de son Key Vault
resource "azurerm_role_assignment" "app_reads_secrets" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_container_app.this.identity[0].principal_id
}

# ---------------------------------------------------------------
# DNS (zone privée, souscription IT-Management via le provider azurerm.dns)
# ---------------------------------------------------------------
resource "azurerm_private_dns_cname_record" "this" {
  count    = var.dns != null ? 1 : 0
  provider = azurerm.dns

  name                = local.app_name
  zone_name           = var.dns.zone_name
  resource_group_name = var.dns.rg_name
  ttl                 = 300
  record              = azurerm_container_app.this.ingress[0].fqdn

  tags = local.tags
}
