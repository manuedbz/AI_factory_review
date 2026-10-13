# 01 - Vision

## Objectif

Construire une **usine à sites** : des scripts qui instancient de nouvelles applications « à la volée », à la fois côté **Azure** (infrastructure) et côté **GitHub** (code, CI/CD), à partir de quelques options (nom, connexions…).

## Principe

```
 options (nom, env, connexions)
            │
            ▼
   ┌─────────────────┐
   │  script d'usine │
   └───────┬─────────┘
           ├──► Azure  (Terraform)  → voir 02-architecture-azure.md
           └──► GitHub (template)   → voir 03-github.md
```

## Périmètre

| Priorité | Élément |
|---|---|
| Socle (MVP) | Module Terraform « app » (Key Vault + Container App + enregistrement DNS) |
| Socle (MVP) | Repo GitHub issu d'un template, avec pipeline de build/déploiement |
| Nice to have (vert sur le schéma Lucid) | À lister ici depuis le schéma Lucid (à compléter) |

## Sources

- Schéma Lucid (WIP) : lien partagé en interne (non reproduit ici, repo public).
- Photo du tableau blanc du 2026-10-13 : synthèse dans [02](02-architecture-azure.md) et [03](03-github.md).

## Hors périmètre pour l'instant

- Toute souscription autre que **SandBox**.
- Le déploiement dans le repo `azure` de production (voir [04-decisions.md](04-decisions.md), D-003).
