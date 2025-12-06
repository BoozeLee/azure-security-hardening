#!/bin/bash
# Azure Security Hardening - Manual GitHub Actions Trigger
# High-threat environment protection for kiliaan@bakerstreetproject221b.store

echo "🚨 URGENT: Triggering Azure Security Hardening via GitHub Actions"
echo "📧 Security Contact: kiliaan@bakerstreetproject221b.store"
echo "🌍 Region: West Europe"
echo "🔒 Threat Level: HIGH"
echo ""

# Check GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found. Please install it:"
    echo "   sudo apt install gh"
    echo "   OR manually trigger the workflow in GitHub:"
    echo "   1. Go to your repository on GitHub"
    echo "   2. Click 'Actions' tab"
    echo "   3. Click 'Azure Security Hardening - High Threat Environment'"
    echo "   4. Click 'Run workflow' button"
    echo "   5. Select 'prod' environment and click 'Run workflow'"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    echo "❌ Not in a git repository. Please initialize git and push to GitHub:"
    echo "   git init"
    echo "   git add ."
    echo "   git commit -m 'Add Azure security hardening infrastructure'"
    echo "   git branch -M main"
    echo "   git remote add origin <your-github-repo>"
    echo "   git push -u origin main"
    exit 1
fi

# Check authentication
echo "🔑 Checking GitHub authentication..."
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated to GitHub. Please run: gh auth login"
    exit 1
fi

# Trigger workflow
echo "🚀 Triggering Azure Security Hardening workflow..."
gh workflow run "azure-security-hardening.yml" --field environment=prod

echo "✅ GitHub Actions workflow triggered successfully!"
echo ""
echo "🔍 Monitor progress:"
echo "   gh run watch"
echo "   OR visit: https://github.com/$(gh repo view --json owner,name -q '.owner.login + \"/\" + .name')/actions"
echo ""
echo "📋 Required GitHub Secrets (set these in your repo settings):"
echo "   AZURE_CLIENT_ID     - Azure service principal client ID"
echo "   AZURE_TENANT_ID     - Azure tenant ID"
echo "   AZURE_SUBSCRIPTION_ID - Azure subscription ID"
echo ""
echo "🚨 CRITICAL: Ensure these secrets are configured before the workflow runs!"