#!/usr/bin/env bash
# Crée le repo GitHub d'une app depuis le template front : branche par défaut develop (-> dev),
# main protégée (-> prod, désactivé), fichiers de templates/front/, environnement "dev" et ses variables
# (valeurs issues des sorties Terraform + Key Vault de la factory).
#
# Usage : scripts/create-github-repo.sh <owner/repo> [--dry-run]
# Pré-requis : gh connecté, az connecté, terraform appliqué dans terraform/examples/sandbox
set -euo pipefail

REPO="${1:?Usage: $0 <owner/repo> [--dry-run]}"
DRY="${2:-}"
TEMPLATE="${TEMPLATE_REPO:-urbasolar/template-urba-front}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$ROOT/terraform/examples/sandbox"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

run() { if [ "$DRY" = "--dry-run" ]; then echo "[dry-run] $*"; else "$@"; fi; }

# shellcheck disable=SC1091
source "$ROOT/scripts/load-env.sh" >/dev/null
OUT=$(terraform -chdir="$TF_DIR" output -json app)
get() { echo "$OUT" | python3 -c "import sys,json;print(json.load(sys.stdin)['$1'])"; }

# Paires NOM=valeur (compatible bash 3.2 de macOS : pas de tableaux associatifs)
VARS=(
  "AZURE_CLIENT_ID=$(get client_id)"
  "AZURE_TENANT_ID=$TF_VAR_tenant_id"
  "AZURE_SUBSCRIPTION_ID=$TF_VAR_subscription_id"
  "ACR_NAME=$(get acr_name)"
  "AZURE_RESOURCE_GROUP=$(get rg_name)"
  "CONTAINER_APP_NAME=$(get name)"
  "FACTORY_KEY_VAULT=${AI_FACTORY_KV:-kv-frc-sbx-aifactory}"
)

if gh repo view "$REPO" >/dev/null 2>&1; then
  echo "Repo $REPO existe déjà, création ignorée"
else
  run gh repo create "$REPO" --private --template "$TEMPLATE"
  if [ "$DRY" != "--dry-run" ]; then
    # Le contenu du template est copié en différé : attendre que package.json soit présent
    for _ in $(seq 1 24); do
      gh api "repos/$REPO/contents/package.json" --silent 2>/dev/null && break
      sleep 5
    done
    gh api "repos/$REPO/contents/package.json" --silent || { echo "Template non copié dans $REPO" >&2; exit 1; }
    gh repo clone "$REPO" "$WORK" -- -q
    git -C "$WORK" checkout -q -b develop
    cp -R "$ROOT/templates/front/." "$WORK/"
    # Le yarn.lock du template pointe vers npm-proxy ; le jeton de lecture des pipelines
    # Urbasolar ne couvre que npm-group (même contenu) : sans cela, 401 au yarn install
    sed -i.bak 's#/repository/npm-proxy/#/repository/npm-group/#g' "$WORK/yarn.lock" && rm -f "$WORK/yarn.lock.bak"
    git -C "$WORK" add -A
    git -C "$WORK" commit -q -m "feat: add Docker build and Azure deployment pipelines"
    git -C "$WORK" push -q -u origin develop
    gh repo edit "$REPO" --default-branch develop
    # main protégée : PR obligatoire (1 approbation), pas de force-push
    gh api -X PUT "repos/$REPO/branches/main/protection" --silent --input - <<JSON
{"required_status_checks":null,"enforce_admins":false,
 "required_pull_request_reviews":{"required_approving_review_count":1},
 "restrictions":null,"allow_force_pushes":false,"allow_deletions":false}
JSON
  else
    echo "[dry-run] clone, branche develop, copie de templates/front, branche par défaut, protection de main"
  fi
fi

# L'environnement doit exister avant d'y poser des variables
run gh api -X PUT "repos/$REPO/environments/dev" --silent
for kv in "${VARS[@]}"; do
  run gh variable set "${kv%%=*}" --env dev --repo "$REPO" --body "${kv#*=}"
done

echo "Repo : https://github.com/$REPO"
echo "Variables posées sur l'environnement dev : $(printf "%s " "${VARS[@]%%=*}")"
echo "Secrets/variables d'organisation requis pour lint/tests : voir docs/03-github.md."
