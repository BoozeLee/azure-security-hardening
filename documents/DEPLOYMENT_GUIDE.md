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

Security Recommendations
- Avoid writing app credentials to disk unless strictly necessary. Use KeyVault to store them.
- Protect `create-spn.yml` with GitHub environment approvals in production.
- Rotate the SPN certificate regularly and use KeyVault to create new certs and update secrets.

Troubleshooting
- If `az keyvault set-policy` fails, ensure the identity used to run the command has KeyVault management permissions.
- If `Import-PfxCertificate` fails on Linux, run M365 setup on Windows runner or use AzPS to import into KeyVault for Linux-based Graph auth.
