#!/bin/bash
set -e

echo "🚀 COMPLETE AZURE SECURITY DEPLOYMENT (COST-OPTIMIZED)"
echo "📧 Account: bakerstreetbandit@hotmail.com"
echo "💰 Mode: MINIMAL COST - Estimated $5-15/month"
echo ""

# Register required resource providers
echo "📋 Registering Azure resource providers..."
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Storage  
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.Insights

echo "⏳ Waiting for provider registration (30 seconds)..."
sleep 30

# Check provider status
echo "🔍 Checking provider registration status..."
az provider show -n Microsoft.KeyVault --query "registrationState" --output tsv
az provider show -n Microsoft.Storage --query "registrationState" --output tsv

# Get subscription info
SUB_ID=$(az account show --query "id" --output tsv)
SUB_NAME=$(az account show --query "name" --output tsv)

echo "✅ Using subscription: $SUB_NAME"

# Create resource group
RG_NAME="rg-security-minimal"
LOCATION="westeurope"

echo "📦 Creating resource group: $RG_NAME"
az group create --name "$RG_NAME" --location "$LOCATION" || true

# Generate unique names
TIMESTAMP=$(date +%s)
KV_NAME="kv-min${TIMESTAMP:5}"
ST_NAME="stmin${TIMESTAMP:5}"

echo "🔑 Creating Key Vault (Basic tier)..."
az keyvault create \
    --name "$KV_NAME" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --sku Basic \
    --enabled-for-disk-encryption true

echo "💾 Creating Storage Account (Standard LRS)..."
az storage account create \
    --name "$ST_NAME" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --https-only true

echo "📊 Creating Log Analytics..."
az monitor log-analytics workspace create \
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
echo "   💰 Delete resources when not needed: az group delete --name $RG_NAME"
