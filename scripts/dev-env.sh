#!/usr/bin/env bash
# Exporte dans le shell la config d'une app depuis son Key Vault : pas de fichier .env.
# Usage : eval "$(scripts/dev-env.sh kv-frc-dev-report)" && yarn dev   (après `az login`)
# Les secrets vont directement en variables d'environnement : rien n'est écrit sur disque.
set -euo pipefail

KV="${1:?Usage: eval \"\$($0 <nom-du-keyvault>)\"}"

for name in $(az keyvault secret list --vault-name "$KV" --query "[?attributes.enabled].name" -o tsv); do
  value=$(az keyvault secret show --vault-name "$KV" --name "$name" --query value -o tsv)
  var=$(echo "$name" | tr '[:lower:]-' '[:upper:]_')
  printf "export %s=%q\n" "$var" "$value"
done
