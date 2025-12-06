#!/usr/bin/env bash
# Ensure strict mode
set -euo pipefail

# Source qwe helper if available for dry-run and better logging
if [ -f "${PWD}/scripts/qwe-sh" ]; then
  # shellcheck source=/dev/null
  source "${PWD}/scripts/qwe-sh"
  export QWE_AGENT="rotate-spn-cert"
fi

# Fallback az_or_dry implementation if helper is not present
if ! declare -f az_or_dry >/dev/null 2>&1; then
  az_or_dry() { command az "$@"; }
fi
# rotate-spn-cert.sh <appName> <keyVaultName> [--delete-old-thumbprint <thumbprint>]
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <appName> <keyVaultName> [--delete-old-thumbprint <thumbprint>]"
  exit 1
fi
APP_NAME="$1"
KEYVAULT_NAME="$2"
DELETE_OLD=""
if [ "$#" -ge 4 ]; then
  if [ "$3" = "--delete-old-thumbprint" ]; then
    DELETE_OLD="$4"
  fi
fi

TIMESTAMP=$(date +%s)
NEW_CERT_NAME="spn-${APP_NAME}-cert-rot-${TIMESTAMP}"
echo "Rotating cert for $APP_NAME in KeyVault $KEYVAULT_NAME. New cert: $NEW_CERT_NAME"
USE_KEYVAULT_CERT=true STORE_PASSWORD_IN_KEYVAULT=true STORE_APP_CREDENTIALS_IN_KEYVAULT=true ASSIGN_KEYVAULT_ACCESS_POLICY=true ./azure-sp-create.sh "$APP_NAME" "$KEYVAULT_NAME" "$NEW_CERT_NAME"

# get the newly created app id and thumbprint from app_credentials.json
if [ -f ./app_credentials.json ]; then
  if command -v jq >/dev/null 2>&1; then
    APP_ID=$(jq -r .appId ./app_credentials.json)
    NEW_THUMBPRINT=$(jq -r .thumbprint ./app_credentials.json)
  else
    APP_ID=$(cat ./app_credentials.json | sed -n 's/.*"appId": "\([^"]*\)".*/\1/p')
    NEW_THUMBPRINT=$(cat ./app_credentials.json | sed -n 's/.*"thumbprint": "\([^"]*\)".*/\1/p')
  fi
else
  echo "No app_credentials.json found. Exiting"
  exit 1
fi

echo "New thumbprint: $NEW_THUMBPRINT"
if [ -n "$DELETE_OLD" ]; then
  echo "Deleting old credential with thumbprint $DELETE_OLD"
  # Find keyId for that thumbprint
  KEY_ID=$(az_or_dry ad app credential list --id "$APP_ID" -o tsv --query "[?thumbprint=='$DELETE_OLD'].keyId | [0]")
  if [ -n "$KEY_ID" ]; then
    echo "Found keyId: $KEY_ID. Deleting"
    az_or_dry ad app credential delete --id "$APP_ID" --key-id "$KEY_ID"
  else
    echo "Could not find a credential with thumbprint $DELETE_OLD for app $APP_ID"
  fi
fi

echo "Rotation complete. New thumbprint: $NEW_THUMBPRINT"
echo "Please verify your automation and remove old secrets from Key Vault if required."
# Optionally store new thumbprint in KeyVault
if [ -n "$KEYVAULT_NAME" ]; then
  THUMBPRINT_SECRET_NAME="spn-${APP_NAME}-thumbprint"
  echo "Writing thumbprint secret ${THUMBPRINT_SECRET_NAME} to KeyVault $KEYVAULT_NAME"
  az_or_dry keyvault secret set --vault-name "$KEYVAULT_NAME" --name "$THUMBPRINT_SECRET_NAME" --value "$NEW_THUMBPRINT" >/dev/null
fi
