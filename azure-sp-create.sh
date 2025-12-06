#!/usr/bin/env bash
set -euo pipefail
# Create an Azure AD App with a certificate for non-interactive auth
# Requires: az CLI and logged-in user with app registration permissions
# Optional environment variables:
# - EXPORT_PASSWORD_TO_FILE=true        -> writes the generated PFX password to app_credentials.txt (disabled by default)
# - STORE_PASSWORD_IN_KEYVAULT=true      -> if a Key Vault name is provided, stores the generated PFX password as a secret in Key Vault
# - ASSIGN_KEYVAULT_ACCESS_POLICY=true   -> when set will attempt to set an access policy on KeyVault for the newly created SP
# - STORE_APP_CREDENTIALS_IN_KEYVAULT=true -> store `app_credentials.json` as a Key Vault secret (useful for CI)

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <appName> [<keyVaultName>] [<certBaseName>]"
  exit 1
fi

APP_NAME="$1"
KEYVAULT_NAME="${2:-""}"
# Optional third arg to control the certificate name to import into KeyVault
CERT_BASE_NAME="${3:-""}"

echo "Creating self-signed certificate for $APP_NAME"
if [ -n "$CERT_BASE_NAME" ]; then
  CERT_NAME="$CERT_BASE_NAME"
else
  CERT_NAME="$APP_NAME-cert-$(date +%s)"
fi

# Support creating the certificate in KeyVault instead of locally
if [ "${USE_KEYVAULT_CERT:-false}" = "true" ] && [ -n "$KEYVAULT_NAME" ]; then
  echo "Creating a certificate in KeyVault: $KEYVAULT_NAME (name: $CERT_NAME)"
  # Get default policy and create a self-signed certificate in Key Vault
  KV_POLICY=$(az keyvault certificate get-default-policy)
  az keyvault certificate create --vault-name "$KEYVAULT_NAME" --name "$CERT_NAME" --policy "$KV_POLICY" >/dev/null
  echo "Created certificate in KeyVault: $CERT_NAME"
  # Attempt to retrieve PFX from KeyVault as a Base64 secret
  PFX_BASE64=$(az keyvault secret show --vault-name "$KEYVAULT_NAME" --name "$CERT_NAME" --query value -o tsv 2>/dev/null || true)
  if [ -z "$PFX_BASE64" ]; then
    echo "Could not retrieve PFX from KeyVault secret (maybe KeyVault is using backed cert without PFX export enabled)."
    PFX_PASSWORD=""
  else
    echo "Saving PFX locally: ${CERT_NAME}.pfx"
    echo "$PFX_BASE64" | base64 --decode > "${CERT_NAME}.pfx"
    PFX_PASSWORD=""
  fi
else
  openssl req -x509 -newkey rsa:2048 -keyout "${CERT_NAME}.key" -out "${CERT_NAME}.crt" -days 365 -nodes -subj "/CN=$APP_NAME"
  # generate a reasonably secure random password for the pfx and reuse it
  PFX_PASSWORD=$(openssl rand -hex 16)
  openssl pkcs12 -export -out "${CERT_NAME}.pfx" -inkey "${CERT_NAME}.key" -in "${CERT_NAME}.crt" -password "pass:${PFX_PASSWORD}"
fi

echo "Registering app in Azure AD"
APP_ID=$(az ad app create --display-name "$APP_NAME" --available-to-other-tenants false --query appId -o tsv)
echo "App created: $APP_ID"

echo "Create service principal"
az ad sp create --id "$APP_ID" || true

echo "Upload certificate credential to app"
if [ "${USE_KEYVAULT_CERT:-false}" = "true" ] && [ -n "$KEYVAULT_NAME" ]; then
  # If we were able to write a PFX locally, import from PFX; otherwise attempt to use KeyVault-backed app credential if supported
  if [ -f "${CERT_NAME}.pfx" ]; then
    echo "Importing app credential from local PFX file"
    az ad app credential reset --id "$APP_ID" --cert @${CERT_NAME}.pfx --append >/dev/null
  else
    echo "Attempting to attach KeyVault certificate to app directly (if CLI supports --keyvault)"
    if az ad app credential reset --id "$APP_ID" --keyvault "https://$KEYVAULT_NAME.vault.azure.net" --name "$CERT_NAME" --append >/dev/null 2>&1; then
      echo "App credential created via KeyVault certificate binding"
    else
      echo "KeyVault-backed credential binding is not supported or failed; try re-running with a PFX export enabled in Key Vault or run create-spn.sh without USE_KEYVAULT_CERT."
    fi
  fi
else
  az ad app credential reset --id "$APP_ID" --cert @${CERT_NAME}.crt --append
fi

if [ -n "$KEYVAULT_NAME" ]; then
  echo "Importing certificate to KeyVault $KEYVAULT_NAME"
  # validate the keyvault exists
  if ! az keyvault show --name "$KEYVAULT_NAME" &>/dev/null; then
    echo "KeyVault '$KEYVAULT_NAME' not found. Create it first or pass a valid name."
    exit 1
  fi
  # import the PFX using the same password used to export
  az keyvault certificate import --vault-name "$KEYVAULT_NAME" --name "$CERT_NAME" --file "${CERT_NAME}.pfx" --password "$PFX_PASSWORD"
  echo "Imported certificate to Key Vault as name: ${CERT_NAME}" 
  if [ "${STORE_PASSWORD_IN_KEYVAULT:-false}" = "true" ]; then
    # Use a standard secret name so other scripts and runtimes can discover it based on APP_NAME
    SECRET_PFX_NAME="spn-${APP_NAME}-pfx-password"
    echo "Storing PFX password in Key Vault as secret: ${SECRET_PFX_NAME}"
    az keyvault secret set --vault-name "$KEYVAULT_NAME" --name "$SECRET_PFX_NAME" --value "$PFX_PASSWORD" >/dev/null
  fi
  # Save a standard name referencing the certificate used. This helps runtimes discover the certificate name in KeyVault.
  if [ "${STORE_PASSWORD_IN_KEYVAULT:-false}" = "true" ]; then
    CERT_NAME_SECRET="spn-${APP_NAME}-cert-name"
    echo "Storing certificate name used in Key Vault as secret: ${CERT_NAME_SECRET} -> ${CERT_NAME}"
    az keyvault secret set --vault-name "$KEYVAULT_NAME" --name "$CERT_NAME_SECRET" --value "$CERT_NAME" >/dev/null
  fi
  # Optionally store full app credentials JSON in KeyVault
  if [ "${STORE_APP_CREDENTIALS_IN_KEYVAULT:-false}" = "true" ]; then
    APP_CRED_SECRET_NAME="spn-${APP_NAME}-app-credentials"
    echo "Storing app credentials JSON into Key Vault: $APP_CRED_SECRET_NAME"
    az keyvault secret set --vault-name "$KEYVAULT_NAME" --name "$APP_CRED_SECRET_NAME" --value "$(cat ./app_credentials.json)" >/dev/null
  fi
  # Optionally assign KeyVault access policy to created SP
  if [ "${ASSIGN_KEYVAULT_ACCESS_POLICY:-false}" = "true" ]; then
    echo "Assigning KeyVault access policy to App (objectId will be resolved automatically)"
    # resolve object id for the SP
    SP_OBJECT_ID=$(az ad sp show --id "$APP_ID" --query objectId -o tsv)
    if [ -z "$SP_OBJECT_ID" ]; then
      echo "Failed to resolve service principal object id for $APP_ID. Aborting RBAC assignment."
    else
      echo "SP ObjectId: $SP_OBJECT_ID"
      echo "Granting certificate/get/import and secret/get/list/set permissions"
      if az keyvault set-policy --name "$KEYVAULT_NAME" --object-id "$SP_OBJECT_ID" --certificate-permissions get import list --secret-permissions get list set --key-permissions get wrapKey unwrapKey >/dev/null 2>&1; then
        echo "Assigned KeyVault access policy for SP $APP_ID"
      else
        echo "Failed to set KeyVault access policy via set-policy. Attempting RBAC role assignment as fallback."
        KV_SCOPE=$(az keyvault show --name "$KEYVAULT_NAME" --query id -o tsv)
        if az role assignment create --assignee-object-id "$SP_OBJECT_ID" --role 'Key Vault Certificates Officer' --scope "$KV_SCOPE" >/dev/null 2>&1; then
          echo "Assigned KeyVault RBAC role 'Key Vault Certificates Officer' for SP $APP_ID"
        else
          echo "Failed to assign KeyVault RBAC role; you may need elevated privileges to assign roles. Please run manually."
        fi
      fi
    fi
  fi
fi

THUMBPRINT=$(openssl x509 -noout -fingerprint -in ${CERT_NAME}.crt | sed 's/://g' | sed 's/.*=//')
echo "AppId: $APP_ID" > ./app_credentials.txt
echo "Cert file: ${CERT_NAME}.crt" >> ./app_credentials.txt
echo "Thumbprint (local): $THUMBPRINT" >> ./app_credentials.txt
echo "SPClientId=$APP_ID" >> ./app_credentials.txt
echo "SPThumbprint=$THUMBPRINT" >> ./app_credentials.txt
printf '{"appId": "%s", "thumbprint": "%s"}\n' "$APP_ID" "$THUMBPRINT" > ./app_credentials.json
echo "Created helper JSON: ./app_credentials.json" 
if [ -n "$KEYVAULT_NAME" ]; then
  # Save the thumbprint in KeyVault for easier discovery of installed certs
  THUMBPRINT_SECRET_NAME="spn-${APP_NAME}-thumbprint"
  echo "Storing thumbprint in KeyVault secret: ${THUMBPRINT_SECRET_NAME}"
  az keyvault secret set --vault-name "$KEYVAULT_NAME" --name "$THUMBPRINT_SECRET_NAME" --value "$THUMBPRINT" >/dev/null
fi
if [ -n "$KEYVAULT_NAME" ]; then
  echo "Key Vault: $KEYVAULT_NAME" >> ./app_credentials.txt
  echo "KeyVault secret (pfx password): ${SECRET_PFX_NAME:-''}" >> ./app_credentials.txt
  echo "KeyVault cert name secret: ${CERT_NAME_SECRET:-''}" >> ./app_credentials.txt
fi
# write the PFX password to the credentials file only if the user asked (to avoid accidental leakage), otherwise print reminder to store it safely
if [ "${EXPORT_PASSWORD_TO_FILE:-false}" = "true" ]; then
  echo "PFX password: $PFX_PASSWORD" >> ./app_credentials.txt
else
  echo "PFX password generated (not written to file). To export, set EXPORT_PASSWORD_TO_FILE=true before running the script." >> ./app_credentials.txt
fi

echo "Created app and certificate. Save app_credentials.txt securely and add the cert thumbprint to your automation settings."
echo "Environment options: set EXPORT_PASSWORD_TO_FILE=true to write PFX password to app_credentials.txt."
echo "Environment options: set STORE_PASSWORD_IN_KEYVAULT=true to store the PFX password into Key Vault when --keyVaultName is supplied."
