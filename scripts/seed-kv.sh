#!/usr/bin/env bash
# Alimente le Key Vault de la factory avec les identifiants Azure courants.
# Usage : scripts/seed-kv.sh <dns-subscription-id>   (après `az login`, souscription SandBox active)
set -euo pipefail
KV_NAME="${AI_FACTORY_KV:-kv-frc-sbx-aifactory}"
DNS_SUB="${1:?Usage: $0 <dns-subscription-id>}"

set_secret() { az keyvault secret set --vault-name "$KV_NAME" --name "$1" --value "$2" --output none && echo "ok: $1"; }

set_secret tenant-id "$(az account show --query tenantId -o tsv)"
set_secret sandbox-subscription-id "$(az account show --query id -o tsv)"
set_secret dns-subscription-id "$DNS_SUB"
