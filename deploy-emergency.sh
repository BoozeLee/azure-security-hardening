#!/bin/bash
set -e

echo "🚀 EMERGENCY AZURE SECURITY DEPLOYMENT"
echo "📧 Account: bakerstreetbandit@hotmail.com"
echo "💰 COST-CONSCIOUS MODE"
echo ""

# Function to check provider status
check_provider() {
    local provider=$1
    local status=$(az provider show -n $provider --query "registrationState" --output tsv 2>/dev/null || echo "NotRegistered")
    echo "$status"
}

# Register and wait for providers
echo "📋 Ensuring all providers are registered..."
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.OperationalInsights

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
SUB_ID=$(az account show --query "id" --output tsv)
SUB_NAME=$(az account show --query "name" --output tsv)
echo "✅ Using: $SUB_NAME"

# Create resource group
RG_NAME="rg-emergency-security"
LOCATION="westeurope"

echo "📦 Creating resource group..."
az group create --name "$RG_NAME" --location "$LOCATION" --output none

# Generate unique names
TIMESTAMP=$(date +%s)
KV_NAME="kv-emer${TIMESTAMP:7}"
ST_NAME="stemer${TIMESTAMP:7}"

echo "🔑 Creating Key Vault..."
az keyvault create \
    --name "$KV_NAME" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --sku Standard \
    --output none

echo "💾 Creating Storage Account..."
az storage account create \
    --name "$ST_NAME" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --https-only true \
    --output none

echo ""
echo "🎉 EMERGENCY DEPLOYMENT COMPLETE!"
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
