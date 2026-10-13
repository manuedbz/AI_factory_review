# 03 - GitHub

## Repo template

Chaque nouvelle app part d'un **repo template GitHub** (étape ② du tableau blanc).

**Base retenue : `urbasolar/template-urba-front`** (privé, marqué *template*). Le template cible du tableau blanc (Next.js + connecteur DB + `agents.md`) reste à créer ; ce template front sert de point de départ.

### Contenu du template existant

| Élément | Détail |
|---|---|
| Stack | React 18 + TypeScript + Vite, MUI, Zustand, React Query, i18next, PWA, Yarn |
| Authentification | MSAL (Azure AD), désactivable (`VITE_ENABLE_AUTH`) |
| Configuration | Variables `VITE_*` (`VITE_TENANT_ID`, `VITE_FRONT_CLIENT_ID`, `VITE_API_CLIENT_ID`, `VITE_REDIRECT_URI`, `VITE_API_BASE_URL`, `VITE_ENABLE_AUTH`…) |
| Assistance IA | `.github/instructions/copilot.instructions.md`, prompts `clean-template` et `sidebar-config` |
| Documentation | `docs/` (architecture, routing, i18n, API…) |
| CI | Seulement `.gitlab-ci.yml.example` (GitLab) |

### Ecarts avec l'usine (à combler)

| Manque | Conséquence |
|---|---|
| Pas de `Dockerfile` | **Fait (brouillon)** : `templates/front/` (build multi-étapes, nginx port 80 = `target_port` du module) |
| Pas de workflow GitHub Actions | **Fait (brouillon)** : `templates/front/.github/workflows/deploy.yml` |
| Variables `VITE_*` figées au build | Passées en `--build-arg` depuis les variables de l'environnement GitHub. Limite : changer une valeur demande un nouveau build |
| CI GitLab uniquement | L'exemple ne sert que d'inspiration |
| Nettoyage manuel | `@workspace #clean-template` (Copilot Chat) à lancer une fois par nouveau projet : à intégrer ou remplacer dans le script d'usine |

## Plusieurs App Registrations (décision D-008)

Le tableau blanc parle d'une seule « App Reg ». Le template montre que les usages sont distincts, avec des droits séparés :

| Usage | Rôle | Variable | Gestion |
|---|---|---|---|
| **Pipeline** | GitHub Actions pousse l'image et déploie (OIDC) | `AZURE_CLIENT_ID` (environnement GitHub) | Module `terraform/modules/app-registration` (fait) |
| **Front** | Connexion des utilisateurs (MSAL), avec URI de redirection = URL de l'app | `VITE_FRONT_CLIENT_ID` | A faire |
| **API** | Identité exposée par le back, pour les jetons | `VITE_API_CLIENT_ID` | A faire (si l'app a un back) |

## Fichiers prêts pour le template (brouillon)

Dossier `templates/front/` de ce repo, à copier à la racine du template :

| Fichier | Rôle |
|---|---|
| `Dockerfile` | Build Vite (`yarn build`) puis nginx |
| `nginx.conf` | Routage SPA, cache long sur `/assets/`, pas de cache sur `index.html` |
| `.dockerignore` | Exclut `node_modules`, `.env*`, docs |
| `.github/workflows/deploy.yml` | Connexion OIDC, build/push ACR, `az containerapp update` |

Variables à poser dans l'environnement GitHub `dev` : `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `ACR_NAME`, `AZURE_RESOURCE_GROUP`, `CONTAINER_APP_NAME`, et les `VITE_*` (`VITE_ENABLE_AUTH`, `VITE_TENANT_ID`, `VITE_FRONT_CLIENT_ID`, `VITE_API_CLIENT_ID`, `VITE_API_BASE_URL`, `VITE_REDIRECT_URI`).

Vérifié : `yarn install --frozen-lockfile` + `yarn build` sur le template, et syntaxe YAML. **Non vérifié** : build de l'image Docker (daemon arrêté), nginx, workflow sur GitHub.

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
- Appliquer les fichiers de `templates/front/` au repo `urbasolar/template-urba-front` (PR) : à valider.
