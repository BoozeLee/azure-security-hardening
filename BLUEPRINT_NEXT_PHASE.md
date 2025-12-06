# Blueprint: Next Phase — Production Automation & Secure SPN Management

This blueprint describes the next phase for turning this repository into a production-grade automated solution for SPN/certificate creation, safe automation for Microsoft 365, and secure storage and rotation of keys in Key Vault.

## Goals
- Automate SPN & certificate creation for non-interactive automation.
- Securely store all credentials inside Azure Key Vault, not in repository or job logs.
- Provide a CI-hosted Windows runner to demonstrate certificate import for M365 automation.
- Ensure SPN roles and Key Vault permissions are assigned with least privilege.
- Add advanced documentation and runbooks for maintainers and customers.

## Scripts to Deploy (Recommended)
1. `azure-sp-create.sh` — SPN + certificate creation; KeyVault import and optional RBAC setting.
2. `m365-full-setup.ps1` — M365 mailbox creation & license assignment, runs with certificate-based SPN auth from KeyVault.
3. `m365-create-mailbox.ps1` & `m365-assign-license.ps1` — used by `m365-full-setup.ps1` to separate single concerns.
4. `azure-sp-create.sh` helper action (exists as `create-spn.yml`) — CI governor for SPN creation.
5. `stripe_webhook_server.py` — payment webhooks and license issuance (deploy as container or Function App).
6. `sales_bot.py` — outreach automation (optional to deploy in prod; run as scheduled job).

## Guides to Implement
- Quick Start deployable runbooks:
  - How to run SPN creation securely and import into KeyVault.
  - How to run M365 non-interactive automation using KeyVault stored SPN certificate & password.
  - How to run the Windows runner-based `m365-full-setup` workflow.
  - How to rotate certs and revoke SPNs.

## Operational Considerations
- RBAC & elevated operations: assigning KeyVault access policy requires owner or KeyVault admin permissions. Use `ASSIGN_KEYVAULT_ACCESS_POLICY=true` sparingly.
- Security: ensure `AZURE_CREDENTIALS` used in GitHub Actions has least privilege to perform the tasks for the CI host: ability to create AAD apps (if allowed), and to interact with Key Vault. Consider creating a human-operated provisioning step for SPN creation followed by access assignments scoped to the SP.
- Auditing: all actions that change Key Vault access policy or create SPN must be audited; capture logs and GitHub job summaries to security logs.

## Timeline & Priorities
1. Implement and test `ASSIGN_KEYVAULT_ACCESS_POLICY` and `STORE_APP_CREDENTIALS_IN_KEYVAULT` safety gating in `azure-sp-create.sh` (this PR).
2. Create a `protect` workflow for running `create-spn` with approvals and environment protections (GitHub environments + required reviewers).
3. Add RBAC assignment helper to optionally add Key Vault (and subscription) roles for SP (requires elevated privileges).
4. Add `m365-full-setup` Windows runner demonstration and test in CI with sample KeyVault secrets (ran by devs with ephemeral certs).
5. Add runbook to rotate certificates: how to update KeyVault secret, set new cert, add new thumbprint, and deprecate the old cert.

## Acceptance Criteria
- `create-spn` workflow runs non-interactively in CI with `AZURE_CREDENTIALS` and stores secrets in Key Vault.
- `m365-full-setup` retrieves PFX and password, imports it, and uses `Connect-ExchangeOnline` & `Connect-MgGraph` via certificate SPN.
- Demo Windows runner replicates import successfully in a CI environment.
- `azure-sp-create.sh` respects least privilege toggles; default security behavior is conservative.

## Security & Compliance Checklist
- Ensure the CI runner has `AZURE_CREDENTIALS` in GitHub secrets with minimal permissions.
- Turn on mandatory environment approvals for production workflows.
- Use managed identities in the future for automation instead of SPNs, where possible.

## Risks and Mitigations
- Risk: automation sets wide KeyVault permissions if misconfigured.
  - Mitigation: default to not assigning roles. Lock `ASSIGN_KEYVAULT_ACCESS_POLICY` behind an explicit env var and log requirements.
- Risk: storing app credentials in Key Vault might expose them to admins with broad privileges.
  - Mitigation: use separate Key Vault roles and access policies; grant only the app itself necessary scopes and require requestor to add secrets.
