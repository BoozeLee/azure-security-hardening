#!/bin/bash
set -e

# Source qwe helper if available for dry-run wrappers and safe defaults
if [ -f "${PWD}/scripts/qwe-sh" ]; then
    # shellcheck source=/dev/null
    source "${PWD}/scripts/qwe-sh"
    export QWE_AGENT="deploy-complete-minimal"
    send_qwe "Starting complete minimal deploy: $0"
fi

# Provide a fallback az_or_dry if the helper was not available or didn't define it
if ! declare -f az_or_dry >/dev/null 2>&1; then
    az_or_dry() {
        command az "$@"
    }
fi

echo "🚀 COMPLETE AZURE SECURITY DEPLOYMENT (COST-OPTIMIZED)"
echo "📧 Account: bakerstreetbandit@hotmail.com"
echo "💰 Mode: MINIMAL COST - Estimated $5-15/month"
echo ""

# Register required resource providers
echo "📋 Registering Azure resource providers..."
az_or_dry provider register --namespace Microsoft.KeyVault
az_or_dry provider register --namespace Microsoft.Storage  
az_or_dry provider register --namespace Microsoft.OperationalInsights
az_or_dry provider register --namespace Microsoft.Insights

echo "⏳ Waiting for provider registration (30 seconds)..."
sleep 30

# Check provider status
echo "🔍 Checking provider registration status..."
az_or_dry provider show -n Microsoft.KeyVault --query "registrationState" --output tsv
az_or_dry provider show -n Microsoft.Storage --query "registrationState" --output tsv

# Get subscription info
SUB_ID=$(az_or_dry account show --query "id" --output tsv)
SUB_NAME=$(az_or_dry account show --query "name" --output tsv)

echo "✅ Using subscription: $SUB_NAME"

# Create resource group
RG_NAME="rg-security-minimal"
LOCATION="westeurope"

echo "📦 Creating resource group: $RG_NAME"
az_or_dry group create --name "$RG_NAME" --location "$LOCATION" || true

# Generate unique names
TIMESTAMP=$(date +%s)
KV_NAME="kv-min${TIMESTAMP:5}"
ST_NAME="stmin${TIMESTAMP:5}"

echo "🔑 Creating Key Vault (Basic tier)..."
az_or_dry keyvault create \
    --name "$KV_NAME" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --sku Basic \
    --enabled-for-disk-encryption true

echo "💾 Creating Storage Account (Standard LRS)..."
az_or_dry storage account create \
    --name "$ST_NAME" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --https-only true

echo "📊 Creating Log Analytics..."
az_or_dry monitor log-analytics workspace create \
    --workspace-name "law-minimal" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --sku PerGB2018

echo ""
echo "🎉 DEPLOYMENT COMPLETE!"
echo ""
echo "💰 COST BREAKDOWN (Monthly estimates):"
echo "   🔑 Key Vault Basic: ~$1"
echo "   💾 Storage LRS: ~$1-3"
echo "   📊 Log Analytics: ~$2-10" 
echo "   📍 Total: ~$4-14/month"
echo ""
echo "🛡️ SECURITY FEATURES:"
echo "   ✅ Encrypted Key Vault"
echo "   ✅ HTTPS-only storage"
echo "   ✅ Security monitoring"
echo ""
echo "⚠️  COST MONITORING:"
echo "   📊 Set budget alerts: https://portal.azure.com/#blade/Microsoft_Azure_Billing"
echo "   💰 Delete resources when not needed: az_or_dry group delete --name $RG_NAME"
