# 03 - GitHub

## Repo template

Chaque nouvelle app part d'un **repo template GitHub** (étape ② du tableau blanc).

**Base retenue : `urbasolar/template-urba-front`** (privé, marqué *template*). Le template Next.js `urbasolar/template-next-factory` (SSR + MUI + API + PWA) est créé ; ce qui lui manquait pour l'usine (Dockerfile, config au runtime, pipelines) est dans la PR [urbasolar/template-next-factory#3](https://github.com/urbasolar/template-next-factory/pull/3). Usage : `TEMPLATE_REPO=urbasolar/template-next-factory scripts/create-github-repo.sh <owner/repo>`, avec `target_port = 3000` dans le module Terraform `app`. Le connecteur DB et `agents.md` du tableau blanc restent à faire.

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
| `.github/workflows/deploy.yml` | Lint + tests (workflows partagés), puis connexion OIDC, build/push ACR, `az containerapp update` |
| `.github/workflows/on-pull-request.yml` | Lint + tests sur les PR vers `main` (`common-pipelines`) |
| `.github/workflows/pr-title-check.yml` | Contrôle du titre de PR `type(TICKET-123): description` (`common-pipelines`) |
| `.github/workflows/manual-tests.yml` | Lint/tests à la demande |

Variables à poser dans l'environnement GitHub `dev` (posées par `scripts/create-github-repo.sh`) : `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `ACR_NAME`, `AZURE_RESOURCE_GROUP`, `CONTAINER_APP_NAME`, `FACTORY_KEY_VAULT`. Les `VITE_*` viennent du Key Vault de l'app.

**Principe : pas de `.env`, pas de config dans GitHub.** La config et les secrets vivent dans Azure Key Vault ; GitHub ne garde que de quoi se connecter.

| Où | Comment |
|---|---|
| Container App (dev/prod) | Module `app` : `config` (non secret, valeur dans Terraform) et `secret_names` (valeur posée à part). Chaque entrée devient un secret du KV de l'app (`VITE_TENANT_ID` -> `vite-tenant-id`), référencé par la Container App via une identité managée, injecté en variable d'environnement. `40-runtime-env.sh` les applique au bundle au démarrage |
| Poste de dev | `eval "$(scripts/dev-env.sh kv-frc-dev-report)" && yarn dev` (après `az login`) : variables exportées dans le shell, rien écrit sur disque |
| Poser un secret | `scripts/set-secret.sh <keyvault> <VARIABLE>` (valeur saisie sans écho, hors state Terraform) |
| Pipeline | Connexion OIDC, puis lecture du `.npmrc` dans le KV de la factory (secret `npm-npmrc`, rôle Secrets User donné à l'App Registration). Variables GitHub restantes, non secrètes : `AZURE_*`, `ACR_NAME`, `CONTAINER_APP_NAME`, `FACTORY_KEY_VAULT` |

Limites : le KV de l'app est en accès public (RBAC) car la Container App, Terraform et les postes de dev l'atteignent par le réseau public ; à revoir avec un VNet pour la prod. Un secret modifié est relu par la Container App avec un délai (redémarrer la révision pour l'appliquer tout de suite). Les `VITE_*` d'un front sont publics par nature. Le `.npmrc` du KV contient les jetons du registre privé uniquement (pas FontAwesome). On n'utilise plus l'action `common-pipelines/create-npmrc-read-config`.

Vérifié : `yarn install --frozen-lockfile` + `yarn build`, syntaxe YAML, **build Docker local avec secret npmrc, nginx (200, gzip), injection runtime des variables (caractères spéciaux inclus, 0 marqueur restant)**. **Non vérifié** : workflow sur GitHub, lecture du KV et accès au registre npm depuis un runner GitHub, `az containerapp update` avec identités utilisateur (droit d'assigner l'identité à vérifier), workflow sur GitHub. Derrière WARP, le build local nécessite le certificat Cloudflare dans l'image (test uniquement, pas dans le template).

## Compatibilité avec les pipelines habituelles (monitor-front / common-pipelines)

| Élément `common-pipelines` | Statut | Pourquoi |
|---|---|---|
| `do-lint`, `do-test`, `do-pr-title-check` | **Repris tels quels** | Génériques Node/yarn ; `yarn lint` et `yarn test` existent dans le template |
| `do-build-docker` | Non repris | Pousse vers un registre avec identifiant/mot de passe SP, et n'accepte pas de secret BuildKit (le Dockerfile du template s'en sert pour le `.npmrc`) |
| `do-deploy-azure-web-app` | Non repris | Cible les App Service (`app-frc-<env>-<repo>`, secret SP), nous déployons des Container Apps en OIDC |
| `do-create-release-nodejs` (semantic-release) | Non repris pour l'instant | Nécessite les secrets `VERSION_MANAGER_*` ; l'image est taguée avec le SHA du commit. À ajouter si le versionnement est voulu |

Contraintes :
- `common-pipelines` est privé et limité aux repos de l'organisation `urbasolar` : ces workflows **ne fonctionnent pas** dans un repo personnel. Il faut tester dans l'organisation.
- Ils utilisent le runner `urbasolar-azure-core-runner` et des secrets/variables d'organisation (`NPM_REGISTRY_*`, `REPO_CONTENTS_RETRIEVER_*`). La variable de repo `CI_RUNNER` remplace le runner (attention : `ubuntu-latest` reçoit un 403 du registre npm privé).
- Le flux de branches diffère : monitor-front déploie `develop` -> dev et `main` -> preprod ; le template déploie `main` -> dev (pas de prod pour le moment).
- Le lint/les tests ne reçoivent pas la config du KV (pas de connexion Azure) : ils tournent avec les secrets d'organisation, comme monitor-front.

### Constats du premier run réel (`urbasolar/report-demo`, 13/10)

| Constat | Traitement |
|---|---|
| `do-test` exige `deploy/env.template` (action `format-env` : `envsubst` -> `.env`, **affiché dans les logs**) | Fichier minimal ajouté au template, sans valeur secrète |
| Le `yarn.lock` du template pointe vers `npm-proxy`, le jeton de lecture des pipelines ne couvre que `npm-group` : 401 au `yarn install` | `create-github-repo.sh` réécrit les URLs en `npm-group` (même contenu, vérifié). **Correction à reporter dans `urbasolar/template-urba-front`** |
| Le repo issu du template est rempli en différé | Le script attend la présence de `package.json` avant de cloner |
| `yarn lint` échoue sur le code du template (règle `import/no-duplicates` : « typescript with invalid interface loaded as resolver », variables inutilisées, `any`) | Corrigé : PR [urbasolar/template-urba-front#7](https://github.com/urbasolar/template-urba-front/pull/7). Le résolveur `eslint-import-resolver-typescript` n'est pas installable (dépendances absentes du registre privé) : résolveur `node` avec extensions TS |
| 1 test du template échoue en CI (`authentication.test.ts` : « should export msalInstance »), 162 passent | Corrigé dans la même PR (163/163) |
| Dependabot/Renovate : PR « Configure Renovate » créée par l'organisation, son titre ne respecte pas le format du contrôle de titre | Ignorer ou renommer |
| OIDC : `AADSTS700213 No matching federated identity record`. Les nouveaux repos émettent un `sub` à ids immuables : `repo:urbasolar@<id-org>/report-demo@<id-repo>:environment:dev` | Variable `github_subject_prefix` du module `app-registration`, valeur lue par `gh api repos/<owner/repo>/actions/oidc/customization/sub -q .sub_claim_prefix` |
| `yarn install` dans le build Docker : **403** du registre npm privé depuis `ubuntu-latest` (IP des runners GitHub refusées) | Le job `deploy` tourne sur `urbasolar-azure-core-runner` (qui a `docker` et `az`), comme `do-build-docker` |

Après ces corrections, le pipeline `develop` est entièrement vert : lint, tests, OIDC, lecture du `.npmrc` dans le KV, build/push ACR, `az containerapp update`. L'app répond 200 avec l'image taguée par le SHA et la config runtime injectée.

### Premier déploiement du template Next (`urbasolar/next-demo`, 13/10)

| Constat | Traitement |
|---|---|
| Container App en port 3000 avec l'image de démo (port 80) : la révision reste « Activating », Terraform attend | Image bootstrap poussée à la main au premier apply. **À industrialiser** (image de démo écoutant sur le port cible, ou `target_port` de démo puis bascule) |
| Seule la branche par défaut du template (`develop`) est copiée : pas de `main` | Le script crée `main` depuis `develop` et accepte un `develop` existant |
| Rôle Entra « Application Administrator » activé par PIM : 403 à la création de l'App Registration une fois l'activation expirée | Réactiver le rôle PIM avant `terraform apply` |

Résultat : lint, tests, OIDC, build/push ACR, `containerapp update` verts ; `NEXT_PUBLIC_APP_NAME` lu dans le KV et injecté au démarrage.

## Ce que l'usine crée côté GitHub

| Élément | Détail |
|---|---|
| Repo | Créé dans l'organisation `urbasolar` depuis le template, privé. Branche par défaut `develop` (-> dev) ; `main` protégée (PR + 1 approbation, -> prod, désactivé) ; fichiers de `templates/front/` poussés sur `develop` |
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
