# 03 - GitHub

## Repo template

Chaque nouvelle app part d'un **repo template GitHub** (étape ② du tableau blanc).

Contenu pressenti :

- Application **Next.js** avec un connecteur de base de données.
- Fichier `agents.md` (consignes pour les agents IA).
- Workflow `deploy.yml` : pipeline de build et déploiement.

## Ce que l'usine crée côté GitHub

| Élément | Détail |
|---|---|
| Repo | Créé depuis le template, nommé d'après l'app |
| Environnements | `dev`, `prod` (variables et secrets associés) |
| Pipeline | `deploy.yml` : build de l'image → push ACR → déploiement Container App |
| Authentification Azure | À définir (OIDC recommandé, pas de secret longue durée) |

## Questions ouvertes

- Organisation GitHub cible (personnelle pour les tests, `urbasolar` ensuite).
- Création du repo via `gh` (script) ou via Terraform (provider GitHub) ?
- Connexions « INT » du tableau blanc (base de données…) : liste et paramétrage à préciser.
