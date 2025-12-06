#!/bin/bash
set -e

# Try to source centralized qwe helper
if [ -f "${PWD}/scripts/qwe-sh" ]; then
    # shellcheck source=/dev/null
    source "${PWD}/scripts/qwe-sh"
    export QWE_AGENT="deploy-emergency"
    send_qwe "Starting EMERGENCY deployment in ${LOCATION:-westeurope} RG=${RG_NAME:-rg-emergency-security}"
fi

# Fallback: ensure az_or_dry exists even if helper not present
if ! declare -f az_or_dry >/dev/null 2>&1; then
    az_or_dry() { command az "$@"; }
fi

echo "🚀 EMERGENCY AZURE SECURITY DEPLOYMENT"
echo "📧 Account: bakerstreetbandit@hotmail.com"
echo "💰 COST-CONSCIOUS MODE"
echo ""

# Function to check provider status
check_provider() {
    local provider=$1
    local status=$(az_or_dry provider show -n $provider --query "registrationState" --output tsv 2>/dev/null || echo "NotRegistered")
    echo "$status"
}

# Register and wait for providers
echo "📋 Ensuring all providers are registered..."
az_or_dry provider register --namespace Microsoft.KeyVault
az_or_dry provider register --namespace Microsoft.Storage
az_or_dry provider register --namespace Microsoft.OperationalInsights

echo "⏳ Waiting for provider registration..."
for i in {1..12}; do
    kv_status=$(check_provider "Microsoft.KeyVault")
    storage_status=$(check_provider "Microsoft.Storage")
    
    if [[ "$kv_status" == "Registered" && "$storage_status" == "Registered" ]]; then
        echo "✅ All providers registered!"
        break
    fi
    
    echo "   Attempt $i/12: KeyVault=$kv_status, Storage=$storage_status"
    if [ $i -eq 12 ]; then
        echo "⚠️  Proceeding anyway..."
        break
    fi
    sleep 15
done

# Get subscription info
SUB_ID=$(az_or_dry account show --query "id" --output tsv)
SUB_NAME=$(az_or_dry account show --query "name" --output tsv)
echo "✅ Using: $SUB_NAME"

# Create resource group
RG_NAME="rg-emergency-security"
LOCATION="westeurope"

echo "📦 Creating resource group..."
az_or_dry group create --name "$RG_NAME" --location "$LOCATION" --output none

# Generate unique names
TIMESTAMP=$(date +%s)
KV_NAME="kv-emer${TIMESTAMP:7}"
ST_NAME="stemer${TIMESTAMP:7}"

echo "🔑 Creating Key Vault..."
az_or_dry keyvault create \
    --name "$KV_NAME" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --sku Standard \
    --output none

echo "💾 Creating Storage Account..."
az_or_dry storage account create \
    --name "$ST_NAME" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --https-only true \
    --output none

echo ""
echo "🎉 EMERGENCY DEPLOYMENT COMPLETE!"
if type send_qwe >/dev/null 2>&1; then send_qwe "EMERGENCY deployment complete: KV=${KV_NAME:-unknown} ST=${ST_NAME:-unknown} RG=${RG_NAME:-rg-emergency-security}"; fi
echo ""
echo "📊 DEPLOYED:"
echo "   🔑 Key Vault: $KV_NAME"
echo "   💾 Storage: $ST_NAME"
echo "   📍 Location: $LOCATION"
echo ""
echo "💰 Monthly Cost: ~$3-8 USD"
echo "🛡️ Security: BASIC PROTECTION ACTIVE"
echo ""
echo "🌐 Portal: https://portal.azure.com"
