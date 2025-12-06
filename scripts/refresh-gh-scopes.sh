#!/bin/bash
# GitHub Token Scope Refresh and OIDC Validation
# Ensures GitHub Actions has proper permissions for Azure deployment

set -e

echo "🔑 GitHub Token Scope Refresh and OIDC Validation"
echo "=================================================="
echo ""

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found. Installing..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y gh
    else
        echo "⚠️  Please install GitHub CLI manually: https://cli.github.com/"
        exit 1
    fi
fi

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not found. Please install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Verify GitHub authentication
echo "🔍 Verifying GitHub authentication..."
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub. Running: gh auth login"
    gh auth login
fi

# Get repository information
REPO_OWNER=$(gh repo view --json owner -q .owner.login 2>/dev/null || echo "")
REPO_NAME=$(gh repo view --json name -q .name 2>/dev/null || echo "")

if [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ]; then
    echo "⚠️  Not in a GitHub repository. Trying to detect from git remote..."
    GIT_REMOTE=$(git config --get remote.origin.url 2>/dev/null || echo "")
    if [[ $GIT_REMOTE =~ github.com[:/]([^/]+)/([^.]+) ]]; then
        REPO_OWNER="${BASH_REMATCH[1]}"
        REPO_NAME="${BASH_REMATCH[2]}"
        echo "📌 Detected: $REPO_OWNER/$REPO_NAME"
    else
        echo "❌ Could not detect repository. Please run from a GitHub repository."
        exit 1
    fi
fi

echo "✅ Repository: $REPO_OWNER/$REPO_NAME"

# Check GitHub token scopes
echo ""
echo "🔍 Checking GitHub token scopes..."
TOKEN_SCOPES=$(gh auth status 2>&1 | grep -oP "Token scopes: \K.*" || echo "unknown")
echo "   Current scopes: $TOKEN_SCOPES"

REQUIRED_SCOPES=("repo" "workflow" "admin:org" "read:packages")
MISSING_SCOPES=()

for scope in "${REQUIRED_SCOPES[@]}"; do
    if [[ ! $TOKEN_SCOPES =~ $scope ]]; then
        MISSING_SCOPES+=("$scope")
    fi
done

if [ ${#MISSING_SCOPES[@]} -gt 0 ]; then
    echo "⚠️  Missing required scopes: ${MISSING_SCOPES[*]}"
    echo "🔄 Refreshing GitHub token with required scopes..."
    gh auth refresh -s repo -s workflow -s admin:org -s read:packages
    echo "✅ Token scopes refreshed"
else
    echo "✅ All required scopes present"
fi

# Verify Azure OIDC configuration
echo ""
echo "🔍 Verifying Azure OIDC configuration..."

# Check for required secrets
echo "   Checking GitHub secrets..."
REQUIRED_SECRETS=("AZURE_CLIENT_ID" "AZURE_TENANT_ID" "AZURE_SUBSCRIPTION_ID")
MISSING_SECRETS=()

for secret in "${REQUIRED_SECRETS[@]}"; do
    if ! gh secret list | grep -q "^$secret"; then
        MISSING_SECRETS+=("$secret")
        echo "   ❌ Missing: $secret"
    else
        echo "   ✅ Found: $secret"
    fi
done

if [ ${#MISSING_SECRETS[@]} -gt 0 ]; then
    echo ""
    echo "⚠️  Missing required secrets for OIDC authentication:"
    for secret in "${MISSING_SECRETS[@]}"; do
        echo "   - $secret"
    done
    echo ""
    echo "💡 To set up OIDC authentication:"
    echo "   1. Create an Azure App Registration"
    echo "   2. Add federated credentials for GitHub Actions"
    echo "   3. Set the secrets in GitHub repository settings"
    echo ""
    echo "   See: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure"
    exit 1
fi

# Validate Azure credentials if we have environment variables
if [ -n "$AZURE_CLIENT_ID" ] && [ -n "$AZURE_TENANT_ID" ] && [ -n "$AZURE_SUBSCRIPTION_ID" ]; then
    echo ""
    echo "🔍 Validating Azure federated credentials..."
    
    # Check if logged in to Azure
    if az account show &> /dev/null; then
        # Try to get the app registration
        APP_INFO=$(az ad app show --id "$AZURE_CLIENT_ID" 2>/dev/null || echo "")
        
        if [ -n "$APP_INFO" ]; then
            echo "✅ Azure App Registration found"
            
            # Check for federated credentials
            FED_CREDS=$(az ad app federated-credential list --id "$AZURE_CLIENT_ID" 2>/dev/null || echo "[]")
            FED_COUNT=$(echo "$FED_CREDS" | jq '. | length' 2>/dev/null || echo "0")
            
            if [ "$FED_COUNT" -gt 0 ]; then
                echo "✅ Federated credentials configured ($FED_COUNT found)"
                echo "$FED_CREDS" | jq -r '.[] | "   - \(.name): \(.subject)"' 2>/dev/null || echo "   (details unavailable)"
            else
                echo "⚠️  No federated credentials found"
                echo "   You may need to configure GitHub OIDC federation"
            fi
        else
            echo "⚠️  Could not verify app registration (may need permissions)"
        fi
    else
        echo "⚠️  Not logged in to Azure CLI - skipping credential validation"
        echo "   Run 'az login' to validate Azure configuration"
    fi
else
    echo "⚠️  Azure environment variables not set - skipping validation"
fi

# Check for optional QWE_WEBHOOK secret
echo ""
echo "🔍 Checking optional configurations..."
if gh secret list | grep -q "^QWE_WEBHOOK"; then
    echo "✅ QWE_WEBHOOK secret configured (notifications enabled)"
else
    echo "ℹ️  QWE_WEBHOOK not configured (notifications disabled)"
    echo "   Set this secret to enable local development notifications"
fi

echo ""
echo "✅ GitHub scope refresh and validation complete!"
echo ""
echo "📋 Summary:"
echo "   Repository: $REPO_OWNER/$REPO_NAME"
echo "   GitHub Token: ✅ Valid with required scopes"
echo "   GitHub Secrets: ✅ OIDC credentials present"
if [ -n "$APP_INFO" ]; then
    echo "   Azure OIDC: ✅ Configured"
else
    echo "   Azure OIDC: ⚠️  Not validated (run 'az login' for full check)"
fi
echo ""
echo "🚀 Ready for automated deployments!"
