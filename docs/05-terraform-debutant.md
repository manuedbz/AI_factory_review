# 05 - Terraform pour débutant

## Notions

| Terme | Explication |
|---|---|
| **Resource** | Un objet Azure décrit en code (`azurerm_key_vault`…) |
| **Module** | Un dossier réutilisable qui regroupe des resources, avec des entrées (`variable`) et des sorties (`output`) |
| **State** | Fichier qui mémorise ce que Terraform a créé. Ici stocké dans un storage account partagé |
| **Provider** | Plugin qui parle à Azure (`azurerm`) |
| **tfvars** | Fichier de valeurs pour un environnement (`sandbox.tfvars`) |

## Cycle de travail

1. `init` : télécharge les providers et configure le backend.
2. `plan` : montre ce qui serait créé/modifié, **sans rien changer**.
3. `apply` : applique réellement.
4. `destroy` : supprime ce que Terraform gère.

Toujours lire le `plan` avant un `apply`.

## Dans le repo `azure`

Les commandes passent par un script :

```
./run.bash <SUBSCRIPTION> <RESOURCE-GROUP> <COMMANDE>
```

Il nécessite la variable d'environnement `AZ_PROVIDER_CLIENT_SECRET` (à demander à l'équipe, ne jamais la committer).

## Outillage local

- Terraform ≥ 1.8.1 requis par le repo `azure` (installé : 1.16.5).
- Azure CLI ≥ 2.59.0, connecté au tenant (`az login`).
- Souscription active : SandBox.

## Commandes utiles hors plan

- `terraform fmt` : met en forme le code.
- `terraform validate` : vérifie la syntaxe, sans accès à Azure.
