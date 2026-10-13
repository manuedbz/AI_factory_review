#!/usr/bin/env bash
# Charge les valeurs de la factory depuis le Key Vault dans l'environnement.
# Usage : source scripts/load-env.sh   (après `az login`)
KV_NAME="${AI_FACTORY_KV:-kv-frc-sbx-aifactory}"

_load() { # <secret> <variable>
  local v
  v=$(az keyvault secret show --vault-name "$KV_NAME" --name "$1" --query value -o tsv 2>/dev/null) \
    || { echo "Secret '$1' introuvable dans $KV_NAME" >&2; return 1; }
  export "$2=$v"
}

_load tenant-id TF_VAR_tenant_id &&
_load sandbox-subscription-id TF_VAR_subscription_id &&
_load dns-subscription-id TF_VAR_dns_subscription_id &&
echo "Variables TF_VAR_* chargées depuis $KV_NAME"
