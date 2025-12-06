#!/bin/bash
# Quick Azure subscription check and deployment trigger
# Run this as soon as VS subscription benefits are activated

echo "⚡ QUICK AZURE SUBSCRIPTION CHECK"
echo "================================"

# Source helper if present
if [ -f "${PWD}/scripts/qwe-sh" ]; then
    # shellcheck source=/dev/null
    source "${PWD}/scripts/qwe-sh"
    export QWE_AGENT="quick-deploy-check"
fi

# Fallback az_or_dry
if ! declare -f az_or_dry >/dev/null 2>&1; then
    az_or_dry() { command az "$@"; }
fi

# Test Azure authentication and subscription
if az_or_dry account show &>/dev/null; then
        SUBSCRIPTION_NAME=$(az_or_dry account show --query "name" --output tsv)
        SUBSCRIPTION_ID=$(az_or_dry account show --query "id" --output tsv)
    
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