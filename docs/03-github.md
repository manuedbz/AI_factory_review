# 03 - GitHub

## Repo template

Chaque nouvelle app part d'un **repo template GitHub** (étape ② du tableau blanc).

**Base retenue : `urbasolar/template-urba-front`** (privé, marqué *template*). Le template cible du tableau blanc (Next.js + connecteur DB + `agents.md`) reste à créer ; ce template front sert de point de départ.

### Contenu du template existant

| Élément | Détail |
|---|---|
| Stack | React 18 + TypeScript + Vite, MUI, Zustand, React Query, i18next, PWA, Yarn |
| Authentification | MSAL (Azure AD), désactivable (`VITE_ENABLE_AUTH`) |
| Configuration | Variables `VITE_*` (`VITE_AZURE_CLIENT_ID`, `VITE_AZURE_TENANT_ID`, `VITE_AZURE_REDIRECT_URI`, `VITE_API_BASE_URL`…) |
| Assistance IA | `.github/instructions/copilot.instructions.md`, prompts `clean-template` et `sidebar-config` |
| Documentation | `docs/` (architecture, routing, i18n, API…) |
| CI | Seulement `.gitlab-ci.yml.example` (GitLab) |

### Ecarts avec l'usine (à combler)

| Manque | Conséquence |
|---|---|
| Pas de `Dockerfile` | Impossible de construire l'image pour la Container App. Prévoir un build multi-étapes (build Vite puis serveur statique, ex. nginx sur le port 80, valeur par défaut `target_port` du module) |
| Pas de workflow GitHub Actions | Écrire `deploy.yml` (build, push ACR, déploiement) |
| Variables `VITE_*` figées au build | Les valeurs par environnement (client id, API) sont intégrées au build : les passer en arguments de build, ou charger une config au démarrage |
| CI GitLab uniquement | L'exemple ne sert que d'inspiration |
| Nettoyage manuel | `@workspace #clean-template` (Copilot Chat) à lancer une fois par nouveau projet : à intégrer ou remplacer dans le script d'usine |

## Deux rôles distincts pour l'App Registration

Le tableau blanc parle d'une seule « App Reg ». Le template montre qu'il en faut deux usages :

| Usage | Rôle | Où est-ce géré ? |
|---|---|---|
| **Pipeline** | Permet à GitHub Actions de pousser l'image et déployer (OIDC) | Module `terraform/modules/app-registration` (fait) |
| **Connexion utilisateur** | Identité MSAL de la SPA (`VITE_AZURE_CLIENT_ID`), avec URI de redirection de l'app | A faire : redirect URI = URL de l'app, rôles/permissions |

A décider : une seule App Registration pour les deux, ou deux séparées (recommandé : séparées, droits distincts).

## Ce que l'usine crée côté GitHub

| Élément | Détail |
|---|---|
| Repo | Créé depuis le template, nommé d'après l'app |
| Environnements | `dev` pour le moment (`prod` plus tard) |
| Variables d'environnement | `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` (sorties Terraform + Key Vault de la factory) |
| Pipeline | `deploy.yml` : build de l'image, push ACR, déploiement Container App |
| Authentification Azure | OIDC (pas de secret longue durée) |

## Questions ouvertes

- Création du repo via `gh` (script) ou via Terraform (provider GitHub) ?
- Organisation cible : `urbasolar` (le template y est) ; repo de test à créer là ou en personnel ?
- Connexions « INT » du tableau blanc (base de données…) : liste et paramétrage à préciser.
- Faut-il garder le template front pour l'usine ou créer le template Next.js du tableau blanc ?
