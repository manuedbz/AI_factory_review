# 02 - Architecture Azure

## Cible : module Terraform `app`

Un seul module, appelé une fois par application et par environnement, qui crée :

| Ressource | Rôle |
|---|---|
| **Key Vault** | Secrets de l'application |
| **Container App** | Exécution de l'image Docker de l'app |
| **Enregistrement DNS** | Nom d'accès à l'app (zone privée dans `rg-dns`, souscription IT-Management) |

Ce que le tableau blanc ajoute autour du module (étapes ultérieures) :

- **App Registration** (identité du pipeline GitHub dans Entra ID), avec un credential fédéré OIDC par environnement : **dev** et **prod** uniquement (pas d'identité « Infra », décision du 2026-10-13).
- **Container Registry (ACR)** pour les images, alimenté par le pipeline de build.
- **Environnement** : `dev` / `prod` portés par le nom de l'app (ex. `monapp-dev`).

## Entrées du module (proposition)

| Variable | Exemple | Remarque |
|---|---|---|
| `name` | `report` | Nom fonctionnel de l'app |
| `env` | `dev` | Environnement, entre dans le nommage |
| `location` | `francecentral` | Région par défaut |
| `rg_name` | `rg-...` | Resource group cible |
| `image` | `acr.../report:latest` | Image à déployer |
| `tags` | `{ CreatedBy = "terraform" }` | Tags par défaut du repo |

Sorties prévues : URL de l'app, id du Key Vault, identité de la Container App.

## Conventions à respecter (repo `azure` existant)

- Nommage Key Vault : `kv-frc-<env>-<name>`.
- Modules sous `terraform/modules/<catégorie>/az-<ressource>`, fichiers `main.tf`, `variables.tf`, `outputs.tf`.
- `rbac_authorization_enabled = true` sur les Key Vault.
- Tags `createdAt` ignorés dans `lifecycle.ignore_changes`.
- Provider `azurerm ~> 4.0`.
- Commit : `feat:`, `change:`, `refactor:`, `docs:`.

## Cadre de travail

- **Souscription : SandBox uniquement** pour le moment.
- La zone DNS privée vit dans `rg-dns` (souscription IT-Management) : il faut le provider avec alias `it-management`.
- Un *Container Apps Environment* partagé est un prérequis (à créer une fois, puis réutilisé par toutes les apps).

## Questions ouvertes

- Environnement Container Apps : créé par le module ou fourni en entrée ? (proposition : fourni)
- Accès privé uniquement, ou ingress public pour certaines apps ?
- Zone DNS privée exacte à utiliser pour le sandbox.

## Limites connues (état actuel)

- **Pas de prod :** seul l'environnement `dev` est géré pour le moment. Le credential fédéré `prod` est retiré de l'exemple (`environments = ["dev"]`).
- **Droits du pipeline limités à `report-dev` :** le rôle Contributor porte sur cette seule Container App. Ajouter `prod` demandera une app `report-prod` (ou un scope par environnement) et un credential fédéré `prod`.
- **Repo GitHub fictif :** `manuedbz/report-demo` dans l'exemple. La confiance OIDC dépend du nom exact `owner/repo` : à remplacer par le vrai repo.
- **Une App Registration = pipeline uniquement :** pas encore d'identité de connexion utilisateur (MSAL) ni de redirect URI (voir [03](03-github.md)).
- **ACR en accès public, gamme Basic :** acceptable en SandBox. Le repo `azure` utilise Premium + private endpoint : à reprendre avant toute migration.
- **Pas d'image dans l'ACR :** l'app tourne sur l'image de démo Microsoft tant que le pipeline n'existe pas.
- **DNS bloqué :** voir `docs/06-suivi.md`.

Voir aussi : [05-terraform-debutant.md](05-terraform-debutant.md).
