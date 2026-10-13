data "azurerm_client_config" "current" {}

locals {
  app_name = "${var.name}-${var.env}"
  tags     = merge({ CreatedBy = "terraform", App = var.name, Env = var.env }, var.tags)

  # Variable d'environnement -> nom de secret Key Vault (pas de "_" autorisé)
  env_names = toset(concat(keys(var.config), tolist(var.secret_names)))
  kv_secret = { for n in local.env_names : n => lower(replace(n, "_", "-")) }
  use_ident = var.acr != null || length(local.env_names) > 0
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
# Identité de pull ACR : doit exister avec son rôle AcrPull avant la
# Container App (une identité système n'existe qu'après sa création)
# ---------------------------------------------------------------
resource "azurerm_user_assigned_identity" "pull" {
  count = local.use_ident ? 1 : 0

  name                = "id-${local.app_name}-acrpull"
  location            = var.location
  resource_group_name = var.rg_name
  tags                = local.tags

  lifecycle {
    ignore_changes = [tags["createdAt"], tags["updatedAt"], tags["env"], tags["Env"]]
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  count = var.acr != null ? 1 : 0

  scope                = var.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.pull[0].principal_id
}

# ---------------------------------------------------------------
# Configuration et secrets dans le Key Vault, injectés dans la Container App
# ---------------------------------------------------------------
resource "azurerm_role_assignment" "deployer_kv" {
  count = length(local.env_names) > 0 ? 1 : 0

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "ident_reads_kv" {
  count = length(local.env_names) > 0 ? 1 : 0

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.pull[0].principal_id
}

resource "azurerm_key_vault_secret" "config" {
  for_each = var.config

  name         = local.kv_secret[each.key]
  value        = each.value
  key_vault_id = azurerm_key_vault.this.id
  content_type = "config"

  depends_on = [azurerm_role_assignment.deployer_kv]
}

resource "azurerm_key_vault_secret" "secret" {
  for_each = var.secret_names

  name         = local.kv_secret[each.key]
  value        = "a-definir"
  key_vault_id = azurerm_key_vault.this.id
  content_type = "secret"

  depends_on = [azurerm_role_assignment.deployer_kv]

  # La vraie valeur est posée hors Terraform
  lifecycle {
    ignore_changes = [value]
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
    type         = local.use_ident ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = local.use_ident ? [azurerm_user_assigned_identity.pull[0].id] : null
  }

  dynamic "secret" {
    for_each = local.kv_secret
    content {
      name                = secret.value
      identity            = azurerm_user_assigned_identity.pull[0].id
      key_vault_secret_id = "${azurerm_key_vault.this.vault_uri}secrets/${secret.value}"
    }
  }

  dynamic "registry" {
    for_each = var.acr != null ? [var.acr] : []
    content {
      server   = registry.value.login_server
      identity = azurerm_user_assigned_identity.pull[0].id
    }
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
      dynamic "env" {
        for_each = local.kv_secret
        content {
          name        = env.key
          secret_name = env.value
        }
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

  depends_on = [
    azurerm_role_assignment.acr_pull,
    azurerm_role_assignment.ident_reads_kv,
    azurerm_key_vault_secret.config,
    azurerm_key_vault_secret.secret,
  ]

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
