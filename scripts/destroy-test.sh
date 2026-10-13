#!/usr/bin/env bash
# Efface les ressources de TEST de la factory, étape par étape, avec validation.
# Usage : scripts/destroy-test.sh [owner/repo]   (défaut : manuedbz/report-demo)
# Chaque étape demande de taper "oui" ; toute autre réponse l'ignore.
# Le Key Vault de la factory (terraform/bootstrap) n'est PAS touché : il contient
# la configuration. Voir l'étape optionnelle en bas.
set -euo pipefail

REPO="${1:-manuedbz/report-demo}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

confirm() { # <question>
  read -r -p "$1 Taper 'oui' pour confirmer : " a
  [ "$a" = "oui" ]
}

# shellcheck disable=SC1091
source "$ROOT/scripts/load-env.sh" >/dev/null
unset TF_VAR_dns_subscription_id

echo "== 1/3 Azure : exemple sandbox (RG rg-ai-factory-sandbox, ACR, Container App, KV de l'app,"
echo "   App Registration app-report, rôles). Terraform affiche le plan avant de détruire."
if confirm "Détruire les ressources Azure de test ?"; then
  terraform -chdir="$ROOT/terraform/examples/sandbox" destroy
else
  echo "Ignoré."
fi

echo
echo "== 2/3 GitHub : repo $REPO (nécessite le scope delete_repo : gh auth refresh -s delete_repo)"
if gh repo view "$REPO" >/dev/null 2>&1; then
  if confirm "Supprimer définitivement le repo $REPO ?"; then
    gh repo delete "$REPO" --yes
  else
    echo "Ignoré."
  fi
else
  echo "Repo $REPO introuvable, rien à faire."
fi

echo
echo "== 3/3 Key Vault de la factory (kv-frc-sbx-aifactory, rg-ai-factory-core) : OPTIONNEL"
echo "   Il contient tenant/souscriptions. Un Key Vault supprimé reste en 'soft delete' (nom réservé)."
if confirm "Détruire aussi le bootstrap ?"; then
  terraform -chdir="$ROOT/terraform/bootstrap" destroy
else
  echo "Conservé."
fi
