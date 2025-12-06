#!/usr/bin/env bash
set -euo pipefail

# Second script to designate a registered model as the org default
# Usage: export ORG='BoozeLee' PROVIDER_ID='xxx' MODEL_ID='yyy'; ./set-raptor-org-default.sh

ORG="${ORG:-BoozeLee}"
PROVIDER_ID="${PROVIDER_ID:-}"
MODEL_ID="${MODEL_ID:-}"

if [ -z "$PROVIDER_ID" ] || [ -z "$MODEL_ID" ]; then
  echo "Usage: PROVIDER_ID=... MODEL_ID=... ./set-raptor-org-default.sh"
  exit 1
fi

# Patch model to make default
PATCH_PAYLOAD='{"is_default": true}'

echo "Setting model $MODEL_ID from provider $PROVIDER_ID as org default..."
if gh api --method PATCH /orgs/$ORG/ai/providers/$PROVIDER_ID/models/$MODEL_ID --input - <<< "$PATCH_PAYLOAD" >/dev/null 2>&1; then
  echo "✅ Model set as default (if API supports it)."
else
  echo "⚠️ Failed to set default via API. Please set it manually in Copilot Admin UI."
fi

# Verify
echo "Listing provider models to verify..."
gh api /orgs/$ORG/ai/providers/$PROVIDER_ID/models --method GET --jq '.[] | {id: .id, model_name: .model_name, display_name: .display_name, is_default: .is_default}'
