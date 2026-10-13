#!/usr/bin/env bash
# Pose la valeur d'un secret dans le Key Vault d'une app (hors Terraform, donc hors state).
# Usage : scripts/set-secret.sh <keyvault> <VARIABLE>     (la valeur est demandée sans écho)
# La Container App relit le secret de lui-même ; redémarrer la révision pour l'appliquer tout de suite.
set -euo pipefail

KV="${1:?Usage: $0 <keyvault> <VARIABLE>}"
VAR="${2:?Usage: $0 <keyvault> <VARIABLE>}"
NAME=$(echo "$VAR" | tr '[:upper:]_' '[:lower:]-')

read -r -s -p "Valeur de $VAR : " VALUE; echo
az keyvault secret set --vault-name "$KV" --name "$NAME" --value "$VALUE" --query name -o tsv
