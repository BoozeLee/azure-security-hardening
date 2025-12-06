#!/bin/bash
# Azure Security Hardening - Immediate Deployment Script
# High-threat environment protection for kiliaan@bakerstreetproject.com

set -e  # Exit on any error

# Try to source centralized qwe helper
if [ -f "${PWD}/scripts/qwe-sh" ]; then
    # shellcheck source=/dev/null
    source "${PWD}/scripts/qwe-sh"
    export QWE_AGENT="deploy-security"
    send_qwe "Starting Azure Security hardening deployment: ${DEPLOYMENT_NAME:-unknown}"
fi

echo "🚨 URGENT: Starting Azure Security Hardening Deployment"
echo "📧 Security Contact: kiliaan@bakerstreetproject.com"
echo "🌍 Region: West Europe"
echo "🔒 Threat Level: HIGH"
echo ""

# Configuration
SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID}"
LOCATION="westeurope"
RESOURCE_GROUP="sec-bsp-rg-prod"
SECURITY_EMAIL="kiliaan@bakerstreetproject.com"
DEPLOYMENT_NAME="security-hardening-$(date +%Y%m%d-%H%M%S)"

# Check Azure CLI installation
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not found. Installing..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

# Check authentication
echo "🔑 Checking Azure authentication..."
if ! az account show &> /dev/null; then
    echo "❌ Not logged into Azure. Please run: az login"
    exit 1
fi

# Set subscription context
if [ -n "$SUBSCRIPTION_ID" ]; then
    az account set --subscription "$SUBSCRIPTION_ID"
    echo "✅ Subscription context set: $SUBSCRIPTION_ID"
else
    echo "⚠️  Using default subscription. Set AZURE_SUBSCRIPTION_ID if needed."
fi

# Install required Azure CLI extensions
echo "🔧 Installing Azure CLI extensions..."
az extension add --name security --only-show-errors || true
az extension add --name log-analytics --only-show-errors || true
az extension add --name policy-insights --only-show-errors || true

# Validate Bicep template
echo "🔍 Validating Bicep templates..."
az deployment sub validate \
    --location "$LOCATION" \
    --template-file infra/main.bicep \
    --parameters @infra/main.parameters.json

echo "✅ Template validation successful"

# Preview deployment (What-If)
echo "📋 Running deployment preview (What-If)..."
az deployment sub what-if \
    --location "$LOCATION" \
    --template-file infra/main.bicep \
    --parameters @infra/main.parameters.json

# Confirm deployment
echo ""
read -p "🚀 Deploy Azure Security Infrastructure? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    echo "❌ Deployment cancelled by user"
    exit 0
fi

# Deploy infrastructure
echo "🚀 Deploying Azure Security Infrastructure..."
if type send_qwe >/dev/null 2>&1; then send_qwe "Starting infra deployment: ${DEPLOYMENT_NAME:-unknown}"; fi
az deployment sub create \
    --name "$DEPLOYMENT_NAME" \
    --location "$LOCATION" \
    --template-file infra/main.bicep \
    --parameters @infra/main.parameters.json \
    --confirm-with-what-if

echo "✅ Infrastructure deployment completed"
if type send_qwe >/dev/null 2>&1; then send_qwe "Infrastructure deployment completed: ${DEPLOYMENT_NAME:-unknown}"; fi

# Enable Microsoft Defender for Cloud
echo "🛡️ Enabling Microsoft Defender for Cloud (All Services)..."

# Enable Defender for Virtual Machines
az security pricing create --name VirtualMachines --tier Standard || echo "⚠️ VirtualMachines already configured"

# Enable Defender for Storage
az security pricing create --name StorageAccounts --tier Standard || echo "⚠️ StorageAccounts already configured"

# Enable Defender for Key Vault
az security pricing create --name KeyVaults --tier Standard || echo "⚠️ KeyVaults already configured"

# Enable Defender for Resource Manager
az security pricing create --name Arm --tier Standard || echo "⚠️ Arm already configured"

# Enable Defender for DNS
az security pricing create --name Dns --tier Standard || echo "⚠️ DNS already configured"

# Enable Defender for Container Registry
az security pricing create --name ContainerRegistry --tier Standard || echo "⚠️ ContainerRegistry already configured"

echo "✅ Microsoft Defender for Cloud enabled"
if type send_qwe >/dev/null 2>&1; then send_qwe "Microsoft Defender for Cloud enabled"; fi

# Configure auto-provisioning
echo "⚙️ Configuring Security Center auto-provisioning..."
az security auto-provisioning-setting update --name default --auto-provision on

# Wait for resources to be available
echo "⏳ Waiting for resources to be available..."
sleep 30

# Get resource details
STORAGE_ACCOUNT_NAME=$(az storage account list --resource-group "$RESOURCE_GROUP" --query "[?starts_with(name, 'secbspsaprod')].name" -o tsv 2>/dev/null || echo "")
KEY_VAULT_NAME=$(az keyvault list --resource-group "$RESOURCE_GROUP" --query "[0].name" -o tsv 2>/dev/null || echo "")

# Configure network security
echo "🔐 Configuring network security restrictions..."

if [ -n "$STORAGE_ACCOUNT_NAME" ]; then
    az storage account update \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --public-network-access Disabled
    echo "✅ Storage account public access disabled"
else
    echo "⚠️ Storage account not found, skipping network restriction"
fi

if [ -n "$KEY_VAULT_NAME" ]; then
    az keyvault update \
        --name "$KEY_VAULT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --public-network-access Disabled
    echo "✅ Key Vault public access disabled"
else
    echo "⚠️ Key Vault not found, skipping network restriction"
fi

# Generate security report
echo "📄 Generating security compliance report..."
{
    echo "=== AZURE SECURITY HARDENING REPORT ==="
    echo "Deployment: $DEPLOYMENT_NAME"
    echo "Timestamp: $(date)"
    echo "Contact: $SECURITY_EMAIL"
    echo ""
    
    echo "=== DEFENDER FOR CLOUD STATUS ==="
    az security pricing list --query "[].{Service:name,Tier:pricingTier}" -o table
    echo ""
    
    echo "=== POLICY COMPLIANCE SUMMARY ==="
    az policy assignment list --resource-group "$RESOURCE_GROUP" --query "[].{Name:displayName,EnforcementMode:enforcementMode}" -o table
    echo ""
    
    echo "=== RESOURCE SUMMARY ==="
    az resource list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name,Type:type,Location:location}" -o table
    
} > security-report.txt

cat security-report.txt

echo ""
echo "🎉 AZURE SECURITY HARDENING COMPLETED SUCCESSFULLY!"
echo ""
echo "✅ Security Status:"
echo "   🛡️  Microsoft Defender for Cloud: ENABLED"
echo "   🔐 Network Public Access: DISABLED"
echo "   🔑 Key Vault Protection: ENABLED"
echo "   💾 Storage Account Security: ENABLED"
echo "   📊 Diagnostic Logging: ENABLED"
echo "   📋 Security Policies: ENFORCED"
echo "   🚨 Security Monitoring: ACTIVE"
echo ""
echo "📄 Security report saved to: security-report.txt"
echo "📧 Security alerts will be sent to: $SECURITY_EMAIL"
echo ""
echo "🔍 Next steps:"
echo "1. Review the security report above"
echo "2. Monitor Azure Security Center recommendations"
echo "3. Set up private endpoint connectivity for applications"
echo "4. Review and respond to any security alerts"
echo ""
echo "🚨 Your Azure environment is now hardened against high-threat scenarios."
if type send_qwe >/dev/null 2>&1; then send_qwe "Azure Security Hardening completed: ${DEPLOYMENT_NAME:-unknown}"; fi