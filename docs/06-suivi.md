# 06 - Suivi d'avancement

Légende : ✅ fait · 🔄 en cours · ⬜ à faire

## Préparation

| Statut | Tâche |
|---|---|
| ✅ | Création du repo `AI_factory_review` |
| ✅ | Analyse du repo `azure` (structure, conventions, modules existants) |
| ✅ | Installation de Terraform en local |
| ✅ | Choix compute : Container Apps (D-002) |
| 🔄 | Documentation initiale (ce dossier `docs/`) |

## Module Terraform `app` (SandBox)

| Statut | Tâche |
|---|---|
| ✅ | Squelette du module (`terraform/modules/app`) |
| ✅ | Key Vault (RBAC) |
| ✅ | Container App (+ environnement dans l'exemple sandbox) |
| ✅ | Enregistrement DNS (CNAME privé, optionnel) |
| ✅ | `terraform validate` |
| 🚫 | DNS : bloqué, voir ci-dessous |
| ⬜ | `plan` puis `apply` de `terraform/examples/sandbox` |

## Blocage DNS

- Le compte de travail n'a pas accès à la souscription **IT-Management** (zone DNS privée dans `rg-dns`) : le provider `azurerm.dns` ne peut pas s'authentifier.
- Il manque aussi un rôle d'écriture sur la zone (ex. « Private DNS Zone Contributor ») et le choix de la zone (aucune zone applicative dans `rg-dns`).
- Le CNAME ne suffit pas : pour répondre sous ce nom, la Container App a besoin d'un domaine personnalisé et d'un certificat (non géré par le module).
- Contournement : `dns = null` (défaut). Les apps sont joignables par leur adresse native.
- À faire : accès IT-Management + rôle, zone retenue, domaine personnalisé.

## Key Vault de la factory (SandBox)

| Statut | Tâche |
|---|---|
| ✅ | Bootstrap Terraform (`terraform/bootstrap`) : `rg-ai-factory-core` + `kv-frc-sbx-aifactory` |
| ✅ | Droit RBAC Administrator obtenu, rôle « Key Vault Secrets Officer » attribué |
| ✅ | KV alimenté (`scripts/seed-kv.sh`) : tenant, souscription SandBox, souscription DNS |
| ✅ | Chargement des variables (`source scripts/load-env.sh`) testé |

Note poste de dev : derrière Cloudflare WARP, `az keyvault` peut échouer (`CERTIFICATE_VERIFY_FAILED`) si `REQUESTS_CA_BUNDLE` ne contient pas le certificat Cloudflare. Pointer vers un bundle qui l'inclut.

## ACR et App Registration (SandBox)

| Statut | Tâche |
|---|---|
| ✅ | Module `acr` (Basic, admin désactivé, accès par identité) |
| ✅ | Module `app-registration` (App + SP, credential fédéré GitHub OIDC, AcrPush, Contributor ciblé) |
| ✅ | Module `app` : identité dédiée AcrPull pour tirer l'image depuis l'ACR |
| ✅ | `plan` propre (dev + prod) : 9 créations, 1 modification, 0 suppression |
| ⬜ | `apply` (en attente de validation) |
| ⬜ | Poser `AZURE_CLIENT_ID` / tenant / souscription dans le repo GitHub |

## Côté GitHub

| Statut | Tâche |
|---|---|
| ⬜ | Repo template (Next.js + connecteur DB + `agents.md` + `deploy.yml`) |
| ⬜ | Script de création de repo |

## Étapes suivantes

- App Registration et identités managées.
- Container Registry (ACR).
- Script d'usine unifié (Azure + GitHub).
- Éléments « nice to have » du schéma Lucid.
