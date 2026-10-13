#!/bin/sh
# Exécuté par l'entrypoint nginx au démarrage du conteneur : remplace les marqueurs
# __RUNTIME_<VAR>__ du bundle par les variables d'environnement du conteneur.
# Une même image sert ainsi dev et prod.
set -eu

ROOT=/usr/share/nginx/html
VARS="VITE_ENABLE_AUTH VITE_TENANT_ID VITE_FRONT_CLIENT_ID VITE_API_CLIENT_ID VITE_API_BASE_URL VITE_REDIRECT_URI"

for name in $VARS; do
  eval "value=\${$name:-}"
  # échappe les caractères spéciaux de sed (\ | &)
  escaped=$(printf '%s' "$value" | sed -e 's/[\\|&]/\\&/g')
  grep -rl "__RUNTIME_${name}__" "$ROOT" 2>/dev/null | while read -r file; do
    sed -i "s|__RUNTIME_${name}__|${escaped}|g" "$file"
  done
done
