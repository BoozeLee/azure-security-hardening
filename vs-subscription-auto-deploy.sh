#!/bin/bash
set -euo pipefail

echo "🚀 VISUAL STUDIO SUBSCRIPTION - AUTOMATED AZURE SECURITY DEPLOYMENT"
echo "📧 Contact: kiliaan@bakerstreetproject.com" 
echo "🌍 Region: West Europe"
echo "🔒 Threat Level: MAXIMUM PROTECTION"
echo ""

# Source qwe helper if available for dry-run
if [ -f "${PWD}/scripts/qwe-sh" ]; then
        # shellcheck source=/dev/null
        source "${PWD}/scripts/qwe-sh"
        export QWE_AGENT="vs-subscription-auto-deploy"
fi

# Fallback az_or_dry
if ! declare -f az_or_dry >/dev/null 2>&1; then
    az_or_dry() { command az "$@"; }
fi

# Step 1: Check Azure login
if ! az_or_dry account show &>/dev/null; then
    echo "❌ Not logged into Azure. Please run: az login"
    exit 1
fi

# Step 2: Check for active subscription  
SUBSCRIPTION_COUNT=$(az_or_dry account list --query "length([?state=='Enabled'])" --output tsv)
if [ "$SUBSCRIPTION_COUNT" -eq 0 ]; then
    echo "❌ No active subscription found!"
    echo "🌐 Please visit: https://my.visualstudio.com/Benefits"
    echo "📝 Activate your Azure credits first"
    exit 1
fi

# Step 3: Get subscription info
SUBSCRIPTION_ID=$(az_or_dry account show --query "id" --output tsv)
SUBSCRIPTION_NAME=$(az_or_dry account show --query "name" --output tsv)
echo "✅ Using subscription: $SUBSCRIPTION_NAME"

# Step 4: Deploy security infrastructure
RG_NAME="rg-security-fortress"
LOCATION="westeurope"

echo "📦 Creating resource group..."
az_or_dry group create --name "$RG_NAME" --location "$LOCATION"

echo "🚀 Deploying security infrastructure..."
az_or_dry deployment group create \
    --resource-group "$RG_NAME" \
    --template-file "infra/main-simple.bicep" \
    --name "security-$(date +%s)" \
    --parameters \
        keyVaultName="kv-sec$(date +%s | tail -c 6)" \
        storageAccountName="stsec$(date +%s | tail -c 6)" \
        logAnalyticsWorkspaceName="law-security" \
        securityContactEmail="kiliaan@bakerstreetproject.com" \
        location="$LOCATION"

echo "🛡️ Enabling Microsoft Defender..."
az_or_dry security pricing create --name "StorageAccounts" --tier "Standard"
az_or_dry security pricing create --name "KeyVaults" --tier "Standard"

echo "🎉 SECURITY DEPLOYMENT COMPLETE!"
echo "🔒 Maximum protection is now ACTIVE!"
