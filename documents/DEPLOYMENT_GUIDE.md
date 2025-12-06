### Quick dev example
1) Create a KeyVault (test/dev):
```bash
az group create -n myRg -l westeurope
az keyvault create -n myTestKv -g myRg --location westeurope --sku standard
```

2) Create SPN with a KeyVault-backed certificate in the dev tenant (non-interactive):
```bash
USE_KEYVAULT_CERT=true ASSIGN_KEYVAULT_ACCESS_POLICY=true ASSIGN_KEYVAULT_RBAC=true ./azure-sp-create.sh my-automation-app myTestKv my-automation-app-cert
```
If `ASSIGN_KEYVAULT_ACCESS_POLICY` fails due to insufficient permissions, either allow RBAC fallback:
```bash
ALLOW_KEYVAULT_RBAC_FALLBACK=true ASSIGN_KEYVAULT_RBAC=true ./azure-sp-create.sh my-automation-app myTestKv my-automation-app-cert
```
or force a failure so you can debug and verify permissions explicitly:
```bash
STRICT_RBAC_ASSIGNMENT=true ./azure-sp-create.sh my-automation-app myTestKv my-automation-app-cert
```

3) Validate AAD app credentials by checking the output `app_credentials.json` or using `az` (replace `APP_ID` with actual app id):
```bash
cat app_credentials.json
az ad app credential list --id <APP_ID> -o json | jq -r '.[].thumbprint' | grep -i <THUMBPRINT>
```

# Deployment Guide - Automating SPNs, Key Vault, and M365 Mailbox Setup

This guide shows the recommended steps and checks to deploy and integrate `azure-sp-create.sh` with Key Vault and run `m365-full-setup.ps1` in CI.

Prerequisites
- Azure CLI installed
- `AZURE_CREDENTIALS` secret configured in GitHub with the required permissions
- Repo Secrets: `SP_CLIENT_ID`, `AZURE_TENANT_ID` for the automation SP (if using service principal)
- You must be an Owner/KeyVault admin in Azure to run `ASSIGN_KEYVAULT_ACCESS_POLICY=true`.

Steps
1. Create and configure KeyVault (if not exist)
   - `az keyvault create -n myKeyVault -g myResourceGroup --location westeurope`
2. Run create-spn workflow (or `azure-sp-create.sh`) to create the SPN and import cert
   - If you want the workflow to store the pfx password and app credentials, set the inputs accordingly, but prefer KeyVault storage over a file.

3. If you enabled `ASSIGN_KEYVAULT_ACCESS_POLICY`, confirm the service principal has access by running a list secrets command.
   - `az keyvault secret show --vault-name myKeyVault --name spn-myapp-pfx-password`

4. Use `m365-full-setup.ps1` from a Windows runner (or admin environment) to create mailbox:
   - You can run it locally by setting environment variables: `KEY_VAULT_NAME`, `SP_APP_NAME` and passing your SPClientId & AzureTenantId to the script.

5. Verify mailbox & alias creation
   - `Get-Mailbox -Identity support@bakerstreetproject.com | Format-List DisplayName,PrimarySmtpAddress,EmailAddresses`

6. To rotate the service principal's certificate using the KeyVault-backed flow:
   ```bash
   # Generate and bind a new certificate for SP
   ./rotate-spn-cert.sh my-app-name myKeyVault

   # Optionally delete the old thumbprint after verifying the new one is working
   ./rotate-spn-cert.sh my-app-name myKeyVault --delete-old-thumbprint <old-thumbprint>
   ```

Notes on rotation:
- The script deposits the new thumbprint into KeyVault under `spn-<appName>-thumbprint` for runtime lookup.
- Ensure `ASSIGN_KEYVAULT_ACCESS_POLICY` or `ASSIGN_KEYVAULT_RBAC` are set appropriately when rotating so the app retains required access to KeyVault.

## Development helper script
We added a `dev/dev-create-spn-kv.sh` script to create a Key Vault and register a Service Principal with a KeyVault-created certificate in a dev environment.

To run locally:
```bash
chmod +x ./dev/dev-create-spn-kv.sh
./dev/dev-create-spn-kv.sh --app-name my-dev-app --keyvault my-dev-kv --resource-group myDevRg --location westeurope --cert-base-name my-dev-app-cert
```
Options:
- `--force true|false` — when false the script will exit if a matching Key Vault cert already exists. Set true to re-run.
- `--cert-base-name` — the name of the certificate resource in Key Vault (defaults to `spn-<appName>-cert`).

If you run this in CI via the provided workflow `.github/workflows/dev-create-spn-kv.yml`, ensure `AZURE_CREDENTIALS` is configured in repo secrets and avoid using this action in production without gating.

Security Recommendations
- Avoid writing app credentials to disk unless strictly necessary. Use KeyVault to store them.
- Protect `create-spn.yml` with GitHub environment approvals in production.
- Rotate the SPN certificate regularly and use KeyVault to create new certs and update secrets.

Troubleshooting
- If `az keyvault set-policy` fails, ensure the identity used to run the command has KeyVault management permissions.
- If `Import-PfxCertificate` fails on Linux, run M365 setup on Windows runner or use AzPS to import into KeyVault for Linux-based Graph auth.
