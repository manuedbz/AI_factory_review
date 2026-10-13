#!/usr/bin/env bash
# Crée le repo GitHub d'une app depuis le template front, l'environnement "dev"
# et ses variables (valeurs issues des sorties Terraform + Key Vault de la factory).
#
# Usage : scripts/create-github-repo.sh <owner/repo> [--dry-run]
# Pré-requis : gh connecté, az connecté, terraform appliqué dans terraform/examples/sandbox
set -euo pipefail

REPO="${1:?Usage: $0 <owner/repo> [--dry-run]}"
DRY="${2:-}"
TEMPLATE="${TEMPLATE_REPO:-urbasolar/template-urba-front}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$ROOT/terraform/examples/sandbox"

run() { if [ "$DRY" = "--dry-run" ]; then echo "[dry-run] $*"; else "$@"; fi; }

# shellcheck disable=SC1091
source "$ROOT/scripts/load-env.sh" >/dev/null
OUT=$(terraform -chdir="$TF_DIR" output -json app)
get() { echo "$OUT" | python3 -c "import sys,json;print(json.load(sys.stdin)['$1'])"; }

FQDN=$(get fqdn)
# Paires NOM=valeur (compatible bash 3.2 de macOS : pas de tableaux associatifs)
VARS=(
  "AZURE_CLIENT_ID=$(get client_id)"
  "AZURE_TENANT_ID=$TF_VAR_tenant_id"
  "AZURE_SUBSCRIPTION_ID=$TF_VAR_subscription_id"
  "ACR_NAME=$(get acr_name)"
  "AZURE_RESOURCE_GROUP=$(get rg_name)"
  "CONTAINER_APP_NAME=$(get name)"
  "VITE_ENABLE_AUTH=false"
  "VITE_REDIRECT_URI=https://$FQDN"
)

if gh repo view "$REPO" >/dev/null 2>&1; then
  echo "Repo $REPO existe déjà, création ignorée"
else
  run gh repo create "$REPO" --private --template "$TEMPLATE"
fi

# L'environnement doit exister avant d'y poser des variables
run gh api -X PUT "repos/$REPO/environments/dev" --silent
for kv in "${VARS[@]}"; do
  run gh variable set "${kv%%=*}" --env dev --repo "$REPO" --body "${kv#*=}"
done

echo "Repo : https://github.com/$REPO"
echo "Variables posées sur l'environnement dev : $(printf "%s " "${VARS[@]%%=*}")"
echo "A faire à la main : copier templates/front/ dans le repo et poser les secrets/variables npm (voir docs/03-github.md)."
