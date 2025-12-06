## 🔧 Tasks & Roadmap for Non-Interactive Certificate/SPN Automation

This file documents the tasks to support automated, non-interactive SPN/certificate creation and KeyVault-driven automation.

Priority tasks
1. Update `azure-sp-create.sh` to support optional canonical certificate names and standard Key Vault secret naming (spn-<appName>-pfx-password, spn-<appName>-cert-name).
2. Update `m365-full-setup.ps1` to resolve certificates automatically from Key Vault using those standards and import into the local certificate store (when executing non-interactively).
3. Add GitHub Actions workflow to demonstrate secure, non-interactive creation using `azure-sp-create.sh` (already added at `.github/workflows/create-spn.yml`).
4. Add validation checks for Key Vault and RBAC permissions in the script.
5. Add the ability to assign a Key Vault access policy to the created SP (OPTIONAL & requires elevated privileges): `ASSIGN_KEYVAULT_ACCESS_POLICY=true`.
6. Add a Windows-runner GitHub Action to run `m365-full-setup.ps1` and verify certificate import.
7. Add an optional step to store `app_credentials.json` into KeyVault as `spn-<appName>-app-credentials`.
8. Add a `rotate-spn-cert.sh` that creates a new KeyVault-backed certificate and swaps it onto the service principal (and optionally deletes the old credential).
9. Add a `USE_KEYVAULT_CERT=true` mode to `azure-sp-create.sh` to create the certificate directly in KeyVault (no PFX exported) and bind it to the SP.
5. Extend `m365-full-setup.ps1` to support reading Key Vault details from environment variables for CI friendliness.
6. Update README with usage examples, plus guidance on rotating certificates and revoking service principals.
7. Add an optional helper action to push credentials to GitHub Secrets (but we recommend storing in KeyVault instead for security).

Security considerations

Notes for maintainers


Completed items
