#!/bin/bash
set -e

echo "🚀 COST-OPTIMIZED AZURE SECURITY DEPLOYMENT"
echo "📧 Account: bakerstreetbandit@hotmail.com"
echo "💰 Mode: MINIMAL COST (Pay-as-you-go safe)"
echo ""

# Check authentication
if ! az account show &>/dev/null; then
    echo "❌ Not logged in. Run: az login"
    exit 1
fi

# Get subscription info
SUB_ID=$(az account show --query "id" --output tsv)
SUB_NAME=$(az account show --query "name" --output tsv)

echo "✅ Using subscription: $SUB_NAME"
echo "🆔 Subscription ID: $SUB_ID"

# Create resource group
RG_NAME="rg-security-minimal"
LOCATION="westeurope"

echo "📦 Creating resource group: $RG_NAME"
az group create --name "$RG_NAME" --location "$LOCATION"

# Generate unique names
TIMESTAMP=$(date +%s)
KV_NAME="kv-min${TIMESTAMP:5}"
ST_NAME="stmin${TIMESTAMP:5}"

echo "🚀 Deploying MINIMAL COST security infrastructure..."
echo "💰 Estimated monthly cost: $5-15 USD"

# Create Key Vault (Basic tier - lowest cost)
echo "🔑 Creating Key Vault (Basic tier)..."
az keyvault create \
    --name "$KV_NAME" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --sku Basic \
    --enabled-for-disk-encryption true \
    --enabled-for-template-deployment true

# Create Storage Account (Standard LRS - lowest cost)
echo "💾 Creating Storage Account (Standard LRS)..."
az storage account create \
    --name "$ST_NAME" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --access-tier Hot \
    --https-only true \
    --min-tls-version TLS1_2

# Create Log Analytics Workspace (Pay-per-GB - cost controlled)
echo "📊 Creating Log Analytics Workspace..."
az monitor log-analytics workspace create \
    --workspace-name "law-minimal-security" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --sku PerGB2018

echo ""
echo "🎉 MINIMAL COST DEPLOYMENT SUCCESSFUL!"
echo ""
echo "📊 DEPLOYED RESOURCES:"
echo "   🔑 Key Vault: $KV_NAME (Basic tier)"
echo "   💾 Storage: $ST_NAME (Standard LRS)"  
echo "   📊 Log Analytics: law-minimal-security (Pay-per-GB)"
echo "   📍 Location: $LOCATION"
echo ""
echo "💰 COST OPTIMIZATION:"
echo "   ✅ Basic Key Vault (~$1/month)"
echo "   ✅ Standard LRS storage (~$1-3/month)"
echo "   ✅ Log Analytics pay-per-GB (~$2-10/month)"
echo "   ✅ NO premium features enabled"
echo ""
echo "🛡️ SECURITY STATUS: ESSENTIAL PROTECTION ACTIVE"
echo "📧 Contact: kiliaan@bakerstreetproject.com"
echo ""
echo "🌐 View in portal: https://portal.azure.com"
echo ""
echo "⚠️  COST MONITORING:"
echo "   📊 Set up budget alerts at: https://portal.azure.com/#blade/Microsoft_Azure_Billing/ModernBillingMenuBlade/BudgetsAndAlerting"
echo "   💰 Monitor costs daily to avoid surprises"