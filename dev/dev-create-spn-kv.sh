#!/usr/bin/env bash
set -euo pipefail
# dev-create-spn-kv.sh - Helper script to create a Key Vault and SPN with a KeyVault-backed certificate for dev testing
# Usage:
#   ./dev/dev-create-spn-kv.sh --app-name my-app --keyvault my-kv --resource-group my-rg --location westeurope --cert-base-name my-app-cert --force false

show_usage() {
  echo "Usage: $0 --app-name <name> --keyvault <kv> [--resource-group <rg>] [--location <loc>] [--cert-base-name <name>] [--force true|false]"
  exit 1
}

APP_NAME=""
KEYVAULT_NAME=""
RESOURCE_GROUP="dev-spn-rg"
LOCATION="westeurope"
CERT_BASE_NAME=""
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-name)
      APP_NAME="$2"; shift 2;;
    --keyvault)
      KEYVAULT_NAME="$2"; shift 2;;
    --resource-group)
      RESOURCE_GROUP="$2"; shift 2;;
    --location)
      LOCATION="$2"; shift 2;;
    --cert-base-name)
      CERT_BASE_NAME="$2"; shift 2;;
    --force)
      FORCE="$2"; shift 2;;
    -h|--help)
      show_usage;;
    *)
      echo "Unknown arg: $1"; show_usage;;
  esac
done

if [ -z "$APP_NAME" ] || [ -z "$KEYVAULT_NAME" ]; then
  echo "app-name and keyvault are required"
  show_usage
fi

if ! command -v az >/dev/null 2>&1; then
  echo "az CLI not found - install and login with 'az login'."
  exit 1
fi

echo "Current subscription: $(az account show 2>/dev/null | jq -r .id || true)"

echo "Ensure resource group $RESOURCE_GROUP exists"
if ! az group show --name "$RESOURCE_GROUP" >/dev/null 2>&1; then
  echo "Creating resource group $RESOURCE_GROUP in $LOCATION"
  az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
else
  echo "Resource group $RESOURCE_GROUP already exists"
fi

echo "Ensure Key Vault $KEYVAULT_NAME exists"
if ! az keyvault show --name "$KEYVAULT_NAME" -g "$RESOURCE_GROUP" >/dev/null 2>&1; then
  echo "Creating Key Vault $KEYVAULT_NAME in rg $RESOURCE_GROUP"
  az keyvault create -n "$KEYVAULT_NAME" -g "$RESOURCE_GROUP" --location "$LOCATION" --sku standard --enable-soft-delete true
else
  echo "Key Vault $KEYVAULT_NAME already exists"
fi

# default to using a deterministic cert base name if not provided
if [ -z "$CERT_BASE_NAME" ]; then
  CERT_BASE_NAME="spn-${APP_NAME}-cert"
fi

echo "Running azure-sp-create.sh to create SPN and KeyVault certificate"
export USE_KEYVAULT_CERT=true
export STORE_PASSWORD_IN_KEYVAULT=true
export STORE_APP_CREDENTIALS_IN_KEYVAULT=true
export ASSIGN_KEYVAULT_ACCESS_POLICY=true
export ASSIGN_KEYVAULT_RBAC=true
export ALLOW_KEYVAULT_RBAC_FALLBACK=true
export STRICT_RBAC_ASSIGNMENT=false

echo "Script flags (safe defaults): USE_KEYVAULT_CERT=$USE_KEYVAULT_CERT, ASSIGN_KEYVAULT_ACCESS_POLICY=$ASSIGN_KEYVAULT_ACCESS_POLICY, ASSIGN_KEYVAULT_RBAC=$ASSIGN_KEYVAULT_RBAC"

chmod +x ./azure-sp-create.sh
./azure-sp-create.sh "$APP_NAME" "$KEYVAULT_NAME" "$CERT_BASE_NAME"

if [ -f ./app_credentials.json ]; then
  if command -v jq >/dev/null 2>&1; then
    APP_ID=$(jq -r .appId ./app_credentials.json)
    THUMBPRINT=$(jq -r .thumbprint ./app_credentials.json)
  else
    APP_ID=$(cat ./app_credentials.json | sed -n 's/.*"appId": "\([^"]*\)".*/\1/p')
    THUMBPRINT=$(cat ./app_credentials.json | sed -n 's/.*"thumbprint": "\([^"]*\)".*/\1/p')
  fi
  echo "App created: $APP_ID; thumbprint: $THUMBPRINT"
  echo "Verifying app credentials in AAD"
  if az ad app credential list --id "$APP_ID" -o json | jq -r '.[].thumbprint' | grep -i "$THUMBPRINT" >/dev/null 2>&1; then
    echo "Validation successful: thumbprint present"
  else
    echo "Validation failed: thumbprint not found in app credentials. Check KeyVault export or CLI capability to bind KeyVault certs to app.";
    exit 1
  fi
else
  echo "No app_credentials.json present after create script. Check logs in azure-sp-create.sh for errors."
  exit 1
fi

echo "Completed dev creation for SPN $APP_NAME (AppId: $APP_ID, Thumbprint: $THUMBPRINT)"
exit 0
