# Module `app` (ébauche)

Crée pour une app : **Key Vault** + **Container App** (identité managée, accès aux secrets) + **enregistrement DNS** privé optionnel.

Contexte et décisions : [docs/02-architecture-azure.md](../../../docs/02-architecture-azure.md).

## Utilisation

Voir [`../../examples/sandbox`](../../examples/sandbox/main.tf) (crée aussi l'environnement Container Apps partagé).

```hcl
module "app" {
  source = "../../modules/app"
  providers = {
    azurerm     = azurerm
    azurerm.dns = azurerm.dns   # souscription portant la zone DNS
  }

  name                         = "report"
  env                          = "dev"
  rg_name                      = "<resource group>"
  container_app_environment_id = "<id de l'environnement>"
}
```

## Ressources créées

| Ressource | Nom |
|---|---|
| Key Vault | `kv-frc-<env>-<name>` |
| Container App | `<name>-<env>` |
| Role assignment | « Key Vault Secrets User » pour l'identité de l'app |
| CNAME privé (si `dns` fourni) | `<name>-<env>` dans la zone indiquée |

## Choix de cette ébauche

- Container Apps Environment **fourni en entrée** (partagé entre apps).
- `min_replicas = 0` par défaut : pas de coût sans trafic.
- L'image est ignorée après création (`ignore_changes`) : le pipeline de déploiement la met à jour.
- Image par défaut : quickstart Microsoft, à remplacer par l'image ACR.

## Limites connues / à faire

- Pas de domaine personnalisé ni de certificat sur la Container App : le CNAME pointe vers le FQDN natif.
- Pas d'App Registration, pas d'ACR, pas de private endpoint Key Vault.
- Zone DNS privée à choisir (aucune zone applicative n'existe dans `rg-dns`).
- Non testé par `plan`/`apply` : seul `terraform validate` a été passé.
