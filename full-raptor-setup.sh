#!/usr/bin/env bash
set -euo pipefail

# Full automation script to register Raptor mini model with GitHub Copilot model hosting
# Usage: export ORG=BoozeLee AZURE_OPENAI_KEY=... AZURE_OPENAI_ENDPOINT=...; ./full-raptor-setup.sh

ORG="${ORG:-}"
SECRET_NAME="${SECRET_NAME:-COPILOT_PROVIDER_AZURE_OPENAI_JSON}"
AZURE_OPENAI_KEY="${AZURE_OPENAI_KEY:-}"
AZURE_OPENAI_ENDPOINT="${AZURE_OPENAI_ENDPOINT:-}"
MODEL_NAME="${MODEL_NAME:-microsoft/raptor-mini-preview}"
DISPLAY_NAME="${DISPLAY_NAME:-Raptor mini (Preview) - Microsoft Fine-Tuned}"
PROVIDER_PREFERENCE="azure_openai" # match provider_kind

# Helper
abort() { echo "\n\033[0;31mError: $*\033[0m\n"; exit 1; }
info() { echo "\033[0;34m$*\033[0m"; }
success() { echo "\033[0;32m$*\033[0m"; }

# Try to source centralized helper if available
if [ -f "${PWD}/scripts/qwe-sh" ]; then
  # shellcheck source=/dev/null
  source "${PWD}/scripts/qwe-sh"
  export QWE_AGENT="full-raptor-setup"
  send_qwe "Starting full-raptor-setup for ORG=${ORG:-unknown}"
fi

# Pre-check gh auth
info "Checking gh authentication..."
if ! gh auth status --hostname github.com &>/dev/null; then
  abort "Please run 'gh auth login' and authenticate with an org admin account."
fi

if [ -z "$ORG" ]; then
  info "No ORG environment variable provided; discovering orgs you belong to..."
  # Ensure jq is installed
  if ! command -v jq &>/dev/null; then
    echo "\n\033[0;33mWarning: 'jq' is required to auto-detect orgs.\033[0m"
    echo "Install jq (apt install jq | brew install jq) or set ORG env var, e.g.: export ORG=your-org"
    abort "Missing 'jq' dependency. Set ORG and try again."
  fi
  ORG_LIST=$(gh api /user/orgs --method GET 2>/dev/null || echo "[]")
  ORG=$(echo "$ORG_LIST" | jq -r '.[0].login // empty')
  if [ -z "$ORG" ]; then
    abort "Could not detect an organization. Set ORG environment variable to the target GitHub org (e.g., export ORG=your-org)."
  fi
  info "Using ORG: $ORG"
fi

info "Checking we can access org: $ORG"
if ! gh api /orgs/$ORG --method GET &>/dev/null; then
  abort "Cannot access org '${ORG}' (no permission or org does not exist). Ensure you are org admin and ORG is correct."
fi

# List providers
info "Listing AI providers for org $ORG..."
PROVIDERS_JSON=$(gh api /orgs/$ORG/ai/providers --method GET 2>/dev/null || echo "")
if [ -z "$PROVIDERS_JSON" ] || echo "$PROVIDERS_JSON" | jq -e '.message? // empty' &>/dev/null; then
  echo "\n\033[0;33mModel-hosting API not available (404) or no providers listed. Please add an Azure/OpenAI provider in the Copilot Admin UI: Organization -> Settings -> Copilot -> Model hosting -> Providers.\033[0m"
  abort "Model-hosting API not accessible. Add provider via UI then re-run the script."
fi
PROVIDER_ID=$(echo "$PROVIDERS_JSON" | jq -r '.[] | select(.provider_kind|test("azure_openai|openai|microsoft";"i")) | .id' | head -n1 || true)

if [ -z "$PROVIDER_ID" ]; then
  abort "No Azure/OpenAI provider found for org $ORG. Please add a provider via Copilot Admin UI (Organization -> Settings -> Copilot -> Model hosting -> Providers)."
fi
info "Using provider: $PROVIDER_ID"

# Create secret
if [ -z "$AZURE_OPENAI_KEY" ] || [ -z "$AZURE_OPENAI_ENDPOINT" ]; then
  abort "Please export AZURE_OPENAI_KEY and AZURE_OPENAI_ENDPOINT environment variables before running the script."
fi

info "Creating org secret: $SECRET_NAME"
# Create a JSON secret with endpoint and API Key
SECRET_JSON=$(jq -nc --arg k "$AZURE_OPENAI_KEY" --arg e "$AZURE_OPENAI_ENDPOINT" '{type:"azure_openai", api_key:$k, endpoint:$e}')
# Create secret (org-level)
gh secret set "$SECRET_NAME" --org "$ORG" --body "$SECRET_JSON"
if type send_qwe >/dev/null 2>&1; then send_qwe "Saved Azure OpenAI credentials as org secret: $SECRET_NAME for $ORG"; fi

# Validate secret
if ! gh secret list --org "$ORG" | grep -q "$SECRET_NAME"; then
  abort "Secret $SECRET_NAME not found after creation. Check permissions."
fi
success "Secret $SECRET_NAME created."

# Register model payload
MODEL_PAYLOAD=$(jq -nc --arg model_name "$MODEL_NAME" --arg display_name "$DISPLAY_NAME" --arg secret_name "$SECRET_NAME" --argjson conf '{"max_tokens":2048, "temperature":0.2, "rate_limit": {"requests_per_minute": 30, "requests_per_day": 5000}, "safety_policy": {"profanity":"redact","pii_filtering":"redact","training_opt_out":true}}' '{model_name: $model_name, display_name: $display_name, provider_model_id: ($model_name|split("/")|.[1]), visibility: "org", is_default: true, credentials_secret_name: $secret_name, configuration: $conf}')

echo "$MODEL_PAYLOAD" > /tmp/model_payload.json

info "Registering model with provider $PROVIDER_ID..."
if type send_qwe >/dev/null 2>&1; then send_qwe "Registering model ${MODEL_NAME} with provider ${PROVIDER_ID}"; fi
set +e
REGISTER_RESPONSE=$(gh api --method POST /orgs/$ORG/ai/providers/${PROVIDER_ID}/models --input /tmp/model_payload.json 2>&1)
RC=$?
set -e

if [ $RC -ne 0 ]; then
  echo "$REGISTER_RESPONSE" | sed 's/^/  /'
  if echo "$REGISTER_RESPONSE" | grep -qi "404\|not\sfound"; then
    abort "Model-hosting API not available for your org. Use the Copilot Admin UI to register the provider + model or contact GitHub support to enable the model-hosting API preview."
  fi
  if echo "$REGISTER_RESPONSE" | grep -qi "403\|permission"; then
    abort "Permission denied while registering the model. Ensure you are an org owner or Copilot admin."
  fi
  abort "Model registration failed. See output above."
fi

MODEL_ID=$(echo "$REGISTER_RESPONSE" | jq -r '.id // .modelId // .name // empty' )
if [ -z "$MODEL_ID" ]; then
  # If command printed no JSON (e.g., CLI outputs message), try fetch models list to find our new model
  MODEL_ID=$(gh api /orgs/$ORG/ai/providers/${PROVIDER_ID}/models --method GET --jq '.[] | select(.model_name=="'$MODEL_NAME'") | .id' | head -n1 || true)
fi

if [ -z "$MODEL_ID" ]; then
  abort "Failed to detect created model id. Please check the provider UI/Logs."
fi
success "Model registered successfully: $MODEL_ID ($MODEL_NAME)"
if type send_qwe >/dev/null 2>&1; then send_qwe "Model registered successfully: ${MODEL_NAME} id=${MODEL_ID}"; fi

# If the model is not default, try to set it default by patch
info "Ensuring model is set as org default..."
PATCH_PAYLOAD=$(jq -nc --argjson p '{is_default: true}' '$p')
set +e
gh api --method PATCH /orgs/$ORG/ai/providers/${PROVIDER_ID}/models/${MODEL_ID} --input <(echo "$PATCH_PAYLOAD") >/dev/null 2>&1
PATCH_RC=$?
set -e
if [ $PATCH_RC -eq 0 ]; then
  success "Model set as org default."
else
  info "Unable to mark model as default via API. Please open Copilot Admin UI and set it as default manually if needed."
fi

# Validate: list models
info "Listing provider models (to confirm):"
gh api /orgs/$ORG/ai/providers/${PROVIDER_ID}/models --method GET --jq '.[] | {id: .id, model_name: .model_name, display_name: .display_name, visibility: .visibility, is_default: .is_default}'

success "Raptor mini model automation complete."
if type send_qwe >/dev/null 2>&1; then send_qwe "Raptor mini model automation complete for ORG=${ORG}"; fi

# Next steps
info "Next steps:"
echo "  - Review Copilot Admin UI to confirm the model settings and visibility."
echo "  - Optionally set RBAC, rate limits or set a different default model."

echo "Done."
