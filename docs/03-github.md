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
| `Dockerfile` | Build Vite (`yarn build`) puis nginx ; le `.npmrc` est monté en secret BuildKit |
| `40-runtime-env.sh` | Au démarrage du conteneur, remplace les marqueurs `__RUNTIME_VITE_*__` du bundle par les variables d'environnement : **une seule image pour dev et prod** (sans modifier le code du template) |
| `nginx.conf` | Routage SPA, gzip, cache long sur `/assets/`, pas de cache sur `index.html` |
| `.dockerignore` | Exclut `node_modules`, `.env*`, docs |
| `.github/workflows/deploy.yml` | Connexion OIDC, build/push ACR, `az containerapp update` |

Variables à poser dans l'environnement GitHub `dev` : `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `ACR_NAME`, `AZURE_RESOURCE_GROUP`, `CONTAINER_APP_NAME`, et les `VITE_*` (`VITE_ENABLE_AUTH`, `VITE_TENANT_ID`, `VITE_FRONT_CLIENT_ID`, `VITE_API_CLIENT_ID`, `VITE_API_BASE_URL`, `VITE_REDIRECT_URI`).

**Registre npm privé** : le `yarn.lock` pointe vers le Nexus Urbasolar, sans `.npmrc` dans le repo. Comme `monitor-front`, le workflow réutilise l'action `urbasolar/common-pipelines/.../create-npmrc-read-config` (secrets/variables d'organisation : `REPO_CONTENTS_RETRIEVER_GITHUB_APP_*`, `NPM_REGISTRY_PRIVATE_GROUP*`, `NPM_REGISTRY_PUBLIC_FONTAWESOME*`). Le `.npmrc` est passé au build en secret BuildKit (jamais dans l'image, contrairement à `COPY .npmrc` de monitor-front) et exclu par `.dockerignore`.

**Configuration runtime** : les `VITE_*` d'auth/API ne sont plus des `--build-arg` ; le workflow les pose en variables d'environnement de la Container App (`az containerapp update --set-env-vars`). Limite : le remplacement se fait une fois par conteneur (un redémarrage garde les valeurs ; un changement de variable crée une révision).

Vérifié : `yarn install --frozen-lockfile` + `yarn build`, syntaxe YAML, **build Docker local avec secret npmrc, nginx (200, gzip), injection runtime des variables (caractères spéciaux inclus, 0 marqueur restant)**. **Non vérifié** : workflow sur GitHub, accès des runners GitHub au registre npm et à la GitHub App (secrets d'organisation à rendre disponibles au repo). Derrière WARP, le build local nécessite le certificat Cloudflare dans l'image (test uniquement, pas dans le template).

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
