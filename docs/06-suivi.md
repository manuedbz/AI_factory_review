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
| ⬜ | Choix de la zone DNS privée |
| ⬜ | `plan` puis `apply` sur SandBox |

## Key Vault de la factory (SandBox)

| Statut | Tâche |
|---|---|
| ✅ | Bootstrap Terraform (`terraform/bootstrap`) : `rg-ai-factory-core` + `kv-frc-sbx-aifactory` créés |
| 🚫 | Rôle « Key Vault Secrets Officer » : refusé (403, pas de droit `roleAssignments/write` sur SandBox) |
| ⬜ | Alimenter le KV : `scripts/seed-kv.sh <dns-subscription-id>` |
| ⬜ | Charger les variables : `source scripts/load-env.sh` |

Impact : le module `app` crée aussi un role assignment (accès de l'app à son Key Vault). Il échouera pareil tant que le droit manque.

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
