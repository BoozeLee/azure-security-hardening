#!/usr/bin/env bash
set -euo pipefail

# Orchestrator script for setting up Raptor model and Azure security via CLI
# Usage: export ORG=... AZURE_OPENAI_KEY=... AZURE_OPENAI_ENDPOINT=...; ./automate-raptor-cli.sh

ORIGINAL_PWD="$PWD"
ORG="${ORG:-}"
SECRET_NAME="${SECRET_NAME:-COPILOT_PROVIDER_AZURE_OPENAI_JSON}"
AZURE_OPENAI_KEY="${AZURE_OPENAI_KEY:-}"
AZURE_OPENAI_ENDPOINT="${AZURE_OPENAI_ENDPOINT:-}"
QWE_URL="${QWE_URL:-http://127.0.0.1:9001/api/v1/agents/message}"

# Dependencies: gh, jq, az
for dep in jq curl; do
  if ! command -v $dep &>/dev/null; then
    echo "Error: $dep is required but not installed. Install $dep and re-run."
    exit 1
  fi
done


# Source centralized QWE helper (scripts/qwe-sh)
if [ -f "${ORIGINAL_PWD}/scripts/qwe-sh" ]; then
  # If the script is invoked directly, set QWE_AGENT from filename
  export QWE_AGENT="${QWE_AGENT:-automate-raptor-cli}"
  # shellcheck source=/dev/null
  source "${ORIGINAL_PWD}/scripts/qwe-sh"
else
  echo "Warning: scripts/qwe-sh not found; QWE notifications disabled (set QWE_URL manually to enable)."
fi

# Safe wrapper for send_qwe to avoid failing if QWE helper isn't loaded
safe_send_qwe() {
  if type send_qwe >/dev/null 2>&1; then
    send_qwe "$@"
  fi
}


# Check gh auth
echo "🔒 Checking GitHub CLI authentication and scopes..."
if ! gh_or_dry auth status --hostname github.com &>/dev/null; then
  echo "Please run 'gh auth login' and authenticate with an org admin account."
  safe_send_qwe "gh auth not authenticated. Please gh auth login as org admin."
  exit 1
fi

# Refresh auth to ensure admin:org
echo "If gh lacks admin:org scope, please run: gh auth refresh -h github.com -s admin:org"

# auto detect org if not set
if [ -z "$ORG" ]; then
  ORG=$(gh_or_dry api /user/orgs --jq '.[0].login' 2>/dev/null || true)
  if [ -z "$ORG" ]; then
    echo "Unable to auto-detect an org. Please set ORG env var: export ORG=your-org"
    safe_send_qwe "Unable to auto-detect an org. Please set ORG=your-org"
    exit 1
  fi
  echo "Using ORG: $ORG"
fi

# Create secret for provider
if [ -z "$AZURE_OPENAI_KEY" ] || [ -z "$AZURE_OPENAI_ENDPOINT" ]; then
  echo "Please set AZURE_OPENAI_KEY and AZURE_OPENAI_ENDPOINT environment variables first."
  safe_send_qwe "Missing AZURE_OPENAI_KEY or AZURE_OPENAI_ENDPOINT environment variables; aborting."
  exit 1
fi

echo "📦 Saving Azure OpenAI credentials as org secret: $SECRET_NAME"
gh_or_dry secret set "$SECRET_NAME" --org "$ORG" --body "$(jq -nc --arg key "$AZURE_OPENAI_KEY" --arg endpoint "$AZURE_OPENAI_ENDPOINT" '{type:"azure_openai", api_key:$key, endpoint:$endpoint}')"
safe_send_qwe "Saved Azure OpenAI credentials as org secret: $SECRET_NAME for $ORG"

# Try to run full-raptor-setup which will attempt to register model and set default
echo "🚀 Running full-raptor-setup.sh"
safe_send_qwe "Starting full-raptor-setup.sh"
if [ "${QWE_DRY_RUN:-false}" = "true" ]; then
  echo "DRY_RUN: Skipping execution of full-raptor-setup.sh"
  safe_send_qwe "DRY_RUN: Skipping full-raptor-setup.sh"
  RC=0
else
  set +e
  ./full-raptor-setup.sh
  RC=$?
  set -e
fi
if [ $RC -eq 0 ]; then
  echo "✅ full-raptor-setup completed successfully."
  safe_send_qwe "full-raptor-setup completed successfully for $ORG"
else
  echo "⚠️ full-raptor-setup failed with exit code $RC. Attempting provider registration via API..."
  safe_send_qwe "full-raptor-setup failed with exit code $RC - attempting provider registration via API"
  # Attempt provider registration
  PROVIDER_PAYLOAD=$(jq -n --arg name "Azure OpenAI (Copilot)" --arg kind "azure_openai" --arg creds "$SECRET_NAME" '{name: $name, provider_kind: $kind, credentials_secret_name: $creds}')
  set +e
  REGISTER_PROVIDER_RESPONSE=$(gh_or_dry api --method POST /orgs/$ORG/ai/providers --input - <<< "$PROVIDER_PAYLOAD" 2>&1)
  REG_RC=$?
  set -e
  echo "$REGISTER_PROVIDER_RESPONSE"
  if [ $REG_RC -ne 0 ]; then
    echo "❌ Provider registration via API failed or not available. Please add a provider manually in the Copilot Admin UI: Organization -> Settings -> Copilot -> Model hosting -> Providers."
    safe_send_qwe "Provider registration via API failed. Manual provider creation required in Copilot Admin UI."
    exit 1
  fi
  PROVIDER_ID=$(echo "$REGISTER_PROVIDER_RESPONSE" | jq -r '.id // .providerId // empty')
  echo "✅ Provider registered via API: $PROVIDER_ID"
  safe_send_qwe "Provider registered via API: $PROVIDER_ID"
  echo "Now retrying full-raptor-setup.sh"
  ./full-raptor-setup.sh
  RC2=$?
  if [ $RC2 -ne 0 ]; then
    echo "❌ Registration still failed after provider creation. Inspect the output, or check the Copilot Admin UI."
    exit 1
  fi
fi

# Run admin setup for RBAC, budgets, alerts
echo "🔧 Running raptor-admin-setup.sh to configure RBAC, budgets and alerts"
# Need PROVIDER_ID and MODEL_ID - attempt to auto-detect
PROVIDER_ID=$(gh_or_dry api /orgs/$ORG/ai/providers --jq '.[] | select(.provider_kind|test("azure_openai|openai|microsoft";"i")) | .id' | head -n1 || true)
MODEL_ID=$(gh_or_dry api /orgs/$ORG/ai/providers/$PROVIDER_ID/models --jq '.[] | select(.model_name|test("raptor";"i")) | .id' | head -n1 || true)

if [ -z "$PROVIDER_ID" ] || [ -z "$MODEL_ID" ]; then
  echo "Failed to detect PROVIDER_ID or MODEL_ID. Please set them manually and run raptor-admin-setup.sh."
  safe_send_qwe "Failed to detect PROVIDER_ID or MODEL_ID. Please set them manually and run raptor-admin-setup.sh."
  exit 1
fi
export PROVIDER_ID MODEL_ID
if [ "${QWE_DRY_RUN:-false}" = "true" ]; then
  echo "DRY_RUN: Skipping raptor-admin-setup.sh"
  safe_send_qwe "DRY_RUN: Skipping raptor-admin-setup.sh"
else
  ./raptor-admin-setup.sh
  safe_send_qwe "Completed raptor-admin-setup.sh: PROVIDER_ID=$PROVIDER_ID MODEL_ID=$MODEL_ID"
fi

# Optionally set model as org default via second script
if [ "${QWE_DRY_RUN:-false}" = "true" ]; then
  echo "DRY_RUN: Skipping set-raptor-org-default.sh"
else
  ./set-raptor-org-default.sh || echo "Set default API failed - set it manually in Admin UI if needed"
fi

# Final validation
echo "\nFinal validation: list providers and models"
gh api /orgs/$ORG/ai/providers --jq '.[] | {id, name, provider_kind, model_count}' || true
if [ -n "$PROVIDER_ID" ]; then
  gh api /orgs/$ORG/ai/providers/$PROVIDER_ID/models --jq '.[] | {id: .id, model_name: .model_name, display_name: .display_name, is_default: .is_default}' || true
fi

cd "$ORIGINAL_PWD"
safe_send_qwe "Automated setup run completed. If any step failed, review the output or UI and re-run the script after manual corrections."
echo "Done: automated setup run completed. If any step failed, review the output or UI and re-run the script after manual corrections."
