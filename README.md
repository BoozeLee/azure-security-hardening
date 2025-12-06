# Azure Security Hardening Project

> **High-threat environment protection** for Azure infrastructure deployment using Infrastructure as Code (IaC) with maximum security controls.

## 📋 Project Overview

This repository contains Azure Bicep templates and GitHub Actions workflows for deploying security-hardened Azure infrastructure. The configuration implements defense-in-depth security principles for high-threat environments.

**Owner:** kiliaan@bakerstreetproject221b.store  
**Environment:** Production  
**Threat Level:** High  
**Compliance:** Required  

## 🏗️ Architecture Components

### Core Infrastructure
- **Key Vault**: Premium tier with HSM-backed keys, private endpoints, and RBAC
- **Storage Account**: ZRS with customer-managed encryption and private endpoints
- **Virtual Network**: DDoS protection, restrictive NSGs, and service endpoints
- **Log Analytics**: Centralized logging with 90-day retention
- **Security Center**: Defender for all services with enhanced features

### Security Features
- ✅ **Zero Public Access** - All resources behind private endpoints
- ✅ **Encryption at Rest & Transit** - Customer-managed keys from Key Vault
- ✅ **Network Isolation** - VNet with restrictive security groups
- ✅ **Advanced Threat Protection** - Defender for all resource types
- ✅ **Comprehensive Logging** - Diagnostic settings for all resources
- ✅ **Policy Enforcement** - Azure Policy for compliance automation
- ✅ **Access Control** - RBAC with least privilege principle

## 📁 Repository Structure

```
security/
├── .vscode/                    # VS Code workspace configuration
│   ├── settings.json          # GitHub Copilot and Azure settings
│   └── extensions.json        # Recommended extensions
├── .github/workflows/          # GitHub Actions workflows
│   └── security-hardening.yml # Main deployment workflow
├── .copilot/                   # GitHub Copilot configuration
│   └── project-context.json   # Project context for AI assistance
├── infra/                      # Bicep infrastructure templates
│   ├── main.bicep             # Main orchestration template
│   ├── keyvault.bicep         # Key Vault with maximum security
│   ├── storage.bicep          # Secure storage configuration
│   ├── network-security.bicep # VNet and NSG configuration
│   ├── security-center.bicep  # Defender for Cloud setup
│   ├── log-analytics.bicep    # Centralized logging
│   └── azure-policy.bicep     # Policy assignments
├── .gitattributes             # Git file handling configuration
└── README.md                  # This file
```

## 🚀 Quick Start

### Prerequisites
- Azure CLI installed and authenticated
- GitHub Copilot extension for VS Code
- Azure Bicep CLI
- Proper Azure permissions (Contributor + Security Admin)

### Setup GitHub Copilot for this Repository

1. **Install Required Extensions** (VS Code will prompt automatically):
   ```bash
   # Core extensions
   code --install-extension github.copilot
   code --install-extension github.copilot-chat
   code --install-extension ms-azuretools.vscode-bicep
   code --install-extension ms-azuretools.vscode-azure-github-copilot
   ```

2. **Open Workspace in VS Code**:
   ```bash
   cd /home/kiliaan/workspace/security
   code .
   ```

3. **Authenticate with GitHub** (for Copilot):
   - Press `Ctrl+Shift+P` → "GitHub Copilot: Sign In"
   - Follow the authentication flow

4. **Verify Copilot is Working**:
   - Open any `.bicep` file
   - Start typing a comment like `// Create a secure storage account`
   - Copilot should provide intelligent suggestions

### Deploy Infrastructure

1. **Login to Azure**:
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Validate Templates**:
   ```bash
   az deployment sub validate \
     --location westeurope \
     --template-file infra/main.bicep \
     --parameters environmentName=prod securityContactEmail=kiliaan@bakerstreetproject221b.store
   ```

3. **Deploy Infrastructure**:
   ```bash
   az deployment sub create \
     --name "security-hardening-$(date +%Y%m%d-%H%M%S)" \
     --location westeurope \
     --template-file infra/main.bicep \
     --parameters environmentName=prod securityContactEmail=kiliaan@bakerstreetproject221b.store
   ```

## 🔧 GitHub Copilot Configuration

This repository is optimized for GitHub Copilot with:

- **Project Context**: Understands Azure security requirements
- **Language Support**: Optimized for Bicep, YAML, and JSON
- **Security Patterns**: Pre-configured for secure coding practices
- **Documentation**: Comprehensive context for better suggestions

### Copilot Features Enabled:
- 🤖 **Intelligent Code Completion** for Bicep templates
- 💬 **Chat-based Assistance** for Azure questions
- 📚 **Context-aware Suggestions** based on security requirements
- 🔍 **Documentation Generation** for infrastructure components
- 🛡️ **Security Best Practices** enforcement

## 📚 Usage Examples

### Ask Copilot Chat:
- "Add a new secure VM configuration to this infrastructure"
- "Review this Bicep template for security vulnerabilities"
- "Generate documentation for the Key Vault configuration"
- "Create a monitoring alert for failed authentication attempts"

### Code Completions:
- Type `// Add diagnostic settings` and let Copilot complete
- Start a new resource definition and get security-first templates
- Get intelligent parameter suggestions based on existing patterns

## 🔐 Security Considerations

- **No Secrets in Code**: All sensitive values use Key Vault references
- **Network Isolation**: All resources use private endpoints
- **Encryption**: Customer-managed keys for all data encryption
- **Monitoring**: Comprehensive logging and alerting configured
- **Compliance**: Azure Policy enforcement for security baselines

## 🤝 Contributing

When contributing to this repository:
1. Use GitHub Copilot for code suggestions and security reviews
2. Follow the established naming conventions (prefix: `sec-bsp`)
3. Ensure all resources implement maximum security controls
4. Update documentation for any new components

## 📞 Support

For questions or issues:
- **Owner**: kiliaan@bakerstreetproject221b.store
- **GitHub Issues**: Use repository issues for tracking
- **Security Concerns**: Contact owner directly for security-related issues

---

**⚠️ Important**: This infrastructure is designed for high-threat environments. Do not modify security settings without proper review and approval.