#!/bin/bash
# Quick Azure subscription check and deployment trigger
# Run this as soon as VS subscription benefits are activated

echo "⚡ QUICK AZURE SUBSCRIPTION CHECK"
echo "================================"

# Test Azure authentication and subscription
if az account show &>/dev/null; then
    SUBSCRIPTION_NAME=$(az account show --query "name" --output tsv)
    SUBSCRIPTION_ID=$(az account show --query "id" --output tsv)
    
    if [[ "$SUBSCRIPTION_NAME" != *"N/A"* ]]; then
        echo "✅ ACTIVE SUBSCRIPTION DETECTED!"
        echo "📝 Name: $SUBSCRIPTION_NAME"
        echo "🆔 ID: $SUBSCRIPTION_ID"
        echo ""
        echo "🚀 LAUNCHING SECURITY DEPLOYMENT..."
        echo ""
        ./auto-deploy-azure-security.sh
    else
        echo "❌ Still tenant-level access only"
        echo "🎯 Complete VS subscription activation at:"
        echo "🌐 https://my.visualstudio.com/benefits"
    fi
else
    echo "❌ Not authenticated to Azure"
    echo "🔑 Please run: az login"
fi