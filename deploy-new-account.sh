#!/bin/bash
set -e

# Source qwe helper if available for dry-run wrappers and safe defaults
if [ -f "${PWD}/scripts/qwe-sh" ]; then
    # shellcheck source=/dev/null
    source "${PWD}/scripts/qwe-sh"
    export QWE_AGENT="deploy-new-account"
    send_qwe "Starting deploy-new-account: $0"
fi

# Fallback az_or_dry to invoke az if helper isn't present
if ! declare -f az_or_dry >/dev/null 2>&1; then
    az_or_dry() { command az "$@"; }
fi

echo "🚀 DEPLOYING AZURE SECURITY WITH BAKERSTREETBANDIT ACCOUNT"
echo "📧 Account: Bakerstreetbandit@hotmail.com"

# Check authentication
if ! az_or_dry account show &>/dev/null; then
    echo "❌ Not logged in. Run: az login"
    exit 1
fi

# Get subscription info
SUB_ID=$(az_or_dry account show --query "id" --output tsv)
SUB_NAME=$(az_or_dry account show --query "name" --output tsv)

if [[ "$SUB_NAME" == *"N/A"* ]]; then
    echo "❌ No active subscription. Get Azure subscription first!"
    exit 1
fi

echo "✅ Using subscription: $SUB_NAME"
echo "🆔 Subscription ID: $SUB_ID"

# Create resource group
RG_NAME="rg-security-bakerstreet"
LOCATION="westeurope"

echo "📦 Creating resource group: $RG_NAME"
az_or_dry group create --name "$RG_NAME" --location "$LOCATION"

# Generate unique names
TIMESTAMP=$(date +%s)
KV_NAME="kv-baker${TIMESTAMP:5}"
ST_NAME="stbaker${TIMESTAMP:5}"

echo "🚀 Deploying security infrastructure..."
az_or_dry deployment group create \
    --resource-group "$RG_NAME" \
    --template-file "infra/main-simple.bicep" \
    --name "security-deployment-$TIMESTAMP" \
    --parameters \
        keyVaultName="$KV_NAME" \
        storageAccountName="$ST_NAME" \
        logAnalyticsWorkspaceName="law-bakerstreet-security" \
        securityContactEmail="kiliaan@bakerstreetproject.com" \
        location="$LOCATION" \
    --verbose

if [ $? -eq 0 ]; then
    echo "🎉 DEPLOYMENT SUCCESSFUL!"
    echo ""
    echo "📊 DEPLOYED RESOURCES:"
    echo "   🔑 Key Vault: $KV_NAME"
    echo "   💾 Storage: $ST_NAME"  
    echo "   📊 Log Analytics: law-bakerstreet-security"
    echo "   📍 Location: $LOCATION"
    echo ""
    echo "🛡️ SECURITY STATUS: MAXIMUM PROTECTION ACTIVE!"
    echo "📧 Contact: kiliaan@bakerstreetproject.com"
    echo ""
    echo "🌐 View in portal: https://portal.azure.com"
else
    echo "❌ Deployment failed!"
    exit 1
fi
