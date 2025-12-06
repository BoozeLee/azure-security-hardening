#!/usr/bin/env bash
set -euo pipefail

# Script: raptor-admin-setup.sh
# Purpose: Configure RBAC, budgets and monitoring after model creation and provider registration.
# Usage: export ORG=BoozeLee PROVIDER_ID=... MODEL_ID=... EMAIL=you@example.com; ./raptor-admin-setup.sh

ORG="${ORG:-BoozeLee}"
PROVIDER_ID="${PROVIDER_ID:-}"
MODEL_ID="${MODEL_ID:-}"
ALLOWED_TEAM="${ALLOWED_TEAM:-}"    # Team slug if restricting
aZ_BUDGET="${AZ_BUDGET:-10}"
SECURITY_EMAIL="${EMAIL:-kiliaan@bakerstreetproject.com}"
SUB_ID="${SUB_ID:-$(az account show --query id -o tsv)}"
RG_NAME="rg-emergency-security"

if [ -z "$PROVIDER_ID" ] || [ -z "$MODEL_ID" ]; then
  echo "PROVIDER_ID and MODEL_ID must be provided. Example: PROVIDER_ID=xxx MODEL_ID=yyy ./raptor-admin-setup.sh"
  exit 1
fi

# 1) Set model visibility / allowed teams via model-hosting API:
echo "CONFIGURING MODEL RBAC"
PATCH_PAYLOAD='{ "visibility": "org" }'
if [ -n "$ALLOWED_TEAM" ]; then
  PATCH_PAYLOAD=$(jq -nc --arg t "$ALLOWED_TEAM" '{visibility: "selected", allowed_teams: [$t]}')
fi

echo "Setting model visibility via GitHub API..."
set +e
gh api --method PATCH /orgs/$ORG/ai/providers/$PROVIDER_ID/models/$MODEL_ID --input - <<< "$PATCH_PAYLOAD"
RC=$?
set -e
if [ $RC -ne 0 ]; then
  echo "Unable to patch model; ensure you have org admin rights or use the Copilot Admin UI to configure model visibility."
else
  echo "Model visibility updated successfully."
fi

# 2) Create an Azure budget for the subscription to cap cost
echo "\nCONFIGURING AZURE BUDGET"
BUDGET_NAME="security-budget"
# Build filter - optional; keep it simple for subscription
az consumption budget create \
  --subscription "$SUB_ID" \
  --budget-name "$BUDGET_NAME" \
  --category cost \
  --amount $AZ_BUDGET \
  --time-grain Monthly \
  --start-date $(date -u +%Y-%m-01T00:00:00Z) \
  --end-date $(date -u +%Y-%m-01T00:00:00Z -d "+1 year") \
  --notifications amount=8 operator=GreaterThan contact-emails='["$SECURITY_EMAIL"]' 1>/dev/null

if [ $? -eq 0 ]; then
  echo "Azure budget $BUDGET_NAME created at $AZ_BUDGET/month (notifications at 80%=$((AZ_BUDGET*80/100)))."
else
  echo "Failed to create azure budget; check az CLI access, or create the budget in portal. Continuing..."
fi

# 3) Create an action group and alert for budget spike
echo "\nCONFIGURING ACTION GROUP & ALERTS"
AGRG_NAME="actiongroup-security-alerts"
az monitor action-group create \ 
  --resource-group "$RG_NAME" \ 
  --name "$AGRG_NAME" \ 
  --action email $SECURITY_EMAIL --output none || true

# Create activity log alert for admin operations to resource group
ALERT_NAME="Security-Admin-Activity"
az monitor activity-log alert create \
  --name "$ALERT_NAME" \
  --resource-group "$RG_NAME" \
  --condition category=Administrative \
  --action-group "/subscriptions/$SUB_ID/resourceGroups/$RG_NAME/providers/microsoft.insights/actionGroups/$AGRG_NAME" \
  --description "Alert on administrative activities" 1>/dev/null || true

if [ $? -eq 0 ]; then
  echo "Activity log alert created to notify $SECURITY_EMAIL"
else
  echo "Failed to create activity log alert. Continue manual checks."
fi

# 4) Validate model and provider listing
echo "\nVALIDATION: LISTING PROVIDER MODELS"
gh api /orgs/$ORG/ai/providers/$PROVIDER_ID/models --method GET --jq '.[] | {model_name: .model_name, display_name: .display_name, visibility: .visibility, is_default: .is_default}'

echo "\nDone: RBAC, Budgets and basic monitoring configured."
