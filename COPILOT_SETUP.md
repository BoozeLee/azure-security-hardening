# GitHub Copilot Setup Instructions

## 1. Initialize Git Repository (if not already done)

```bash
cd /home/kiliaan/workspace/security

# Initialize git if not already done
git init

# Add all files
git add .

# Initial commit
git commit -m "Initial commit: Azure Security Hardening infrastructure"
```

## 2. Create GitHub Repository

### Option A: Using GitHub CLI (Recommended)
```bash
# Install GitHub CLI if not already installed
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Authenticate with GitHub
gh auth login

# Create repository
gh repo create azure-security-hardening --description "High-threat environment Azure infrastructure with maximum security controls" --public

# Set remote and push
git remote add origin https://github.com/YOUR_USERNAME/azure-security-hardening.git
git branch -M main
git push -u origin main
```

### Option B: Using Git Manually
```bash
# After creating repository on GitHub.com manually
git remote add origin https://github.com/YOUR_USERNAME/azure-security-hardening.git
git branch -M main
git push -u origin main
```

## 3. Install and Setup GitHub Copilot

### Install Extensions
```bash
# Install required VS Code extensions
code --install-extension github.copilot
code --install-extension github.copilot-chat
code --install-extension ms-azuretools.vscode-bicep
code --install-extension ms-azuretools.vscode-azure-github-copilot
code --install-extension redhat.vscode-yaml
code --install-extension ms-azuretools.vscode-azureresourcegroups
```

### Authenticate GitHub Copilot
1. Open VS Code in this directory: `code .`
2. Press `Ctrl+Shift+P`
3. Type "GitHub Copilot: Sign In"
4. Follow the authentication flow
5. Verify by typing in a `.bicep` file - you should see suggestions

## 4. Verify Setup

### Test Copilot Functionality
1. Open `infra/main.bicep`
2. At the end of the file, type:
   ```bicep
   // Add a new secure virtual machine
   ```
3. Copilot should suggest VM configurations with security settings

### Test Copilot Chat
1. Press `Ctrl+Shift+I` to open Copilot Chat
2. Ask: "Explain the security features in this Azure infrastructure"
3. Copilot should provide detailed explanations based on your code

### Verify Context Understanding
1. Open any `.bicep` file
2. Ask Copilot Chat: "What security improvements can be made to this template?"
3. Copilot should provide Azure-specific security recommendations

## 5. Repository Configuration for Better Context

### Add Branch Protection Rules (GitHub.com)
1. Go to repository → Settings → Branches
2. Add rule for `main` branch:
   - Require pull request reviews
   - Require status checks to pass
   - Require branches to be up to date

### Setup GitHub Actions Secrets
1. Go to repository → Settings → Secrets and variables → Actions
2. Add required secrets:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID` 
   - `AZURE_SUBSCRIPTION_ID`

## 6. Troubleshooting

### Copilot Not Working?
```bash
# Check Copilot status
gh copilot --version

# Restart VS Code
# Disable and re-enable Copilot extension
# Check VS Code output panel for Copilot logs
```

### Repository Context Issues?
```bash
# Ensure all files are committed
git status

# Check .gitignore doesn't exclude important files
cat .gitignore

# Refresh VS Code workspace
# Press Ctrl+Shift+P → "Developer: Reload Window"
```

### Language Detection Issues?
```bash
# Verify .gitattributes is working
git check-attr linguist-language infra/main.bicep

# Should output: infra/main.bicep: linguist-language: bicep
```

## 7. Next Steps

1. **Test the complete workflow**: Make a small change and see if Copilot provides relevant suggestions
2. **Explore Copilot Chat**: Ask questions about Azure security best practices
3. **Use Copilot for documentation**: Generate comments and documentation for your infrastructure
4. **Set up continuous integration**: The GitHub Actions workflow is ready to use

Your repository is now fully configured for GitHub Copilot with proper Azure context!