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
| ⬜ | `plan` puis `apply` de `terraform/examples/sandbox` |

## Key Vault de la factory (SandBox)

| Statut | Tâche |
|---|---|
| ✅ | Bootstrap Terraform (`terraform/bootstrap`) : `rg-ai-factory-core` + `kv-frc-sbx-aifactory` |
| ✅ | Droit RBAC Administrator obtenu, rôle « Key Vault Secrets Officer » attribué |
| ✅ | KV alimenté (`scripts/seed-kv.sh`) : tenant, souscription SandBox, souscription DNS |
| ✅ | Chargement des variables (`source scripts/load-env.sh`) testé |

Note poste de dev : derrière Cloudflare WARP, `az keyvault` peut échouer (`CERTIFICATE_VERIFY_FAILED`) si `REQUESTS_CA_BUNDLE` ne contient pas le certificat Cloudflare. Pointer vers un bundle qui l'inclut.

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
