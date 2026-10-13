output "name" {
  value = azurerm_container_app.this.name
}

output "fqdn" {
  description = "Nom d'accès natif de la Container App."
  value       = azurerm_container_app.this.ingress[0].fqdn
}

output "dns_record_fqdn" {
  description = "Nom DNS privé de l'app (null si dns non fourni)."
  value       = try(azurerm_private_dns_cname_record.this[0].fqdn, null)
}

output "key_vault_id" {
  value = azurerm_key_vault.this.id
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "principal_id" {
  description = "Identité managée de l'app."
  value       = azurerm_container_app.this.identity[0].principal_id
}
