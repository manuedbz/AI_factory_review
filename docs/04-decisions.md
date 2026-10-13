# 04 - Décisions

Journal des décisions d'architecture (la plus récente en bas).

## D-001 - Repo de documentation séparé
- **Date** : 2026-10-13
- **Décision** : `AI_factory_review` (public) porte la documentation et le suivi.
- **Contexte** : phase de préparation, le code vivra ensuite ailleurs.

## D-002 - Azure Container Apps plutôt qu'App Service
- **Date** : 2026-10-13
- **Décision** : les apps tournent sur Azure Container Apps.
- **Pourquoi** : paiement à l'usage, pas de plan à dimensionner, une app = une petite ressource isolée, adapté à une usine qui en crée beaucoup.
- **Contrepartie** : aucun module existant dans le repo `azure`, il faut en écrire un et prévoir un Container Apps Environment partagé.
- **Alternative écartée** : App Service (module `az-web-app` existant, mais plan facturé en continu).

## D-003 - Emplacement du module Terraform
- **Date** : 2026-10-13
- **Décision** : le module est développé et documenté dans `AI_factory_review` pour l'instant ; il migrera à terme dans le repo `azure` (`terraform/modules/...`).
- **Conséquence** : respecter dès maintenant les conventions du repo `azure` pour faciliter la migration.

## D-004 - Périmètre Azure : SandBox
- **Date** : 2026-10-13
- **Décision** : travail limité à la souscription **SandBox** du tenant Urbasolar.
- **DNS** : zone privée dans `rg-dns` (souscription IT-Management).

## D-005 - Pas d'identifiants dans le repo
- **Décision** : repo public, donc aucun identifiant de tenant/souscription/client ni secret dans les fichiers.

## D-006 - Environnements : dev uniquement, pas de prod pour l'instant
- **Date** : 2026-10-13
- **Décision** : l'usine ne gère que `dev` ; pas d'identité « Infra ». `prod` viendra plus tard.

## D-007 - Template de départ : template-urba-front
- **Date** : 2026-10-13
- **Décision** : utiliser `urbasolar/template-urba-front` comme base, en attendant le template cible de l'usine.
- **Conséquence** : ajouter Dockerfile et workflow `deploy.yml` (absents du template).
