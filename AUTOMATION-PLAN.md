# Azure Security Hardening - Automation Plan

**Date**: December 6, 2025  
**Owner**: kiliaan@bakerstreetproject.com  
**Status**: Implementation in Progress

## Overview

This document outlines the comprehensive automation plan for Azure security hardening deployment, monitoring, and notification systems.

## Components

### 1. GitHub Token Scope Refresh Automation

**Purpose**: Ensure GitHub OIDC tokens have the necessary scopes for Azure deployment.

**Implementation**:
- Script: `scripts/refresh-gh-scopes.sh`
- Validates current GitHub token permissions
- Refreshes OIDC federation configuration
- Validates Azure federated credentials
- Runs automatically before deployments

**Dependencies**:
- GitHub CLI (`gh`)
- Azure CLI
- GitHub secrets: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`

### 2. Orchestrator with Provider Registration Retry

**Purpose**: Automatically register required Azure resource providers with retry logic.

**Implementation**:
- Enhanced `deploy-security.sh` orchestrator
- Automatic detection of unregistered providers
- Exponential backoff retry mechanism
- Provider registration status validation
- Continues deployment only after all providers are registered

**Providers Required**:
- Microsoft.Security
- Microsoft.PolicyInsights
- Microsoft.OperationalInsights
- Microsoft.Insights
- Microsoft.KeyVault
- Microsoft.Storage
- Microsoft.Network
- Microsoft.Automation
- Microsoft.Consumption

### 3. Budgets, Runbooks, and Action Groups

**Purpose**: Cost control, automated responses, and alert routing.

**Implementation**:

#### A. Azure Budgets (`infra/budget.bicep`)
- Monthly budget thresholds
- Alert triggers at 50%, 75%, 90%, 100%
- Webhook notifications to qwe server
- Action group integration

#### B. Azure Automation Runbooks (`infra/runbooks.bicep`)
- Auto-remediation runbooks:
  - Public access detection and blocking
  - Security policy violation responses
  - Cost anomaly detection
  - Resource compliance enforcement
- Webhook-triggered execution
- Integration with Log Analytics

#### C. Action Groups (`infra/action-groups.bicep`)
- Email notifications to security contact
- Webhook integration for qwe notifications
- SMS alerts for critical events (optional)
- Runbook automation triggers
- Multiple severity levels

### 4. qwe Notification Integration

**Purpose**: Real-time notifications to local development environment and team.

**Implementation**:

#### GitHub Actions Integration (Already Implemented)
- Start notification on workflow trigger
- Success notification on completion
- Failure notification on errors
- Uses `QWE_WEBHOOK` secret

#### Local Orchestrator Integration (New)
- Enhanced `deploy-security.sh` with qwe support
- Notifications at key stages:
  - Deployment start
  - Validation complete
  - Provider registration status
  - Deployment success/failure
  - Security report generation
- Environment variable: `QWE_WEBHOOK`
- Fallback to console-only if webhook not configured

#### qwe Server Setup
- Lightweight HTTP server on port 9001
- Message persistence to `tools/qwe/messages.log`
- REST API: POST `/api/v1/agents/message`
- CLI tool: `tools/qwe/qwe.py`

## Architecture Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    Automation Orchestrator                       │
│                  (automation-orchestrator.sh)                    │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ├─► 1. Refresh GitHub Scopes
                           │    └─► Validate OIDC credentials
                           │
                           ├─► 2. Register Azure Providers
                           │    ├─► Check registration status
                           │    ├─► Register unregistered providers
                           │    └─► Retry with backoff
                           │
                           ├─► 3. Deploy Infrastructure
                           │    ├─► Main Bicep (existing)
                           │    ├─► Budgets
                           │    ├─► Action Groups
                           │    └─► Runbooks
                           │
                           ├─► 4. Configure Defender
                           │    └─► Enable all services
                           │
                           ├─► 5. Validate Deployment
                           │    ├─► Check budgets
                           │    ├─► Verify action groups
                           │    └─► Test runbook webhooks
                           │
                           └─► 6. Send Notifications
                                ├─► Email (Action Groups)
                                ├─► qwe webhook
                                └─► Console output
```

## Notification Flow

```
Azure Event/Alert
       │
       ├─► Action Group
       │    ├─► Email → kiliaan@bakerstreetproject.com
       │    ├─► Webhook → qwe server (local dev)
       │    └─► Runbook → Auto-remediation
       │
       └─► Budget Alert
            ├─► Action Group
            └─► qwe notification
```

## Implementation Steps

### Phase 1: Core Automation Scripts (Current)
- [x] Create automation plan document
- [ ] Implement `scripts/refresh-gh-scopes.sh`
- [ ] Enhance `deploy-security.sh` with:
  - [ ] Provider registration retry logic
  - [ ] qwe notification integration
  - [ ] Validation checks

### Phase 2: Infrastructure Modules
- [ ] Create `infra/budget.bicep`
- [ ] Create `infra/runbooks.bicep`
- [ ] Create `infra/action-groups.bicep`
- [ ] Update `infra/main.bicep` to include new modules

### Phase 3: Integration & Testing
- [ ] Create `automation-orchestrator.sh` master script
- [ ] Update GitHub Actions workflow to use new orchestrator
- [ ] Test qwe notification flow
- [ ] Validate budget alerts
- [ ] Test runbook execution
- [ ] Verify action group webhooks

### Phase 4: Documentation & Validation
- [ ] Update README.md
- [ ] Create runbook documentation
- [ ] Test full automation flow
- [ ] Generate deployment report

## Environment Variables

### Required
```bash
# Azure Authentication
AZURE_SUBSCRIPTION_ID=<subscription-id>
AZURE_TENANT_ID=<tenant-id>
AZURE_CLIENT_ID=<client-id>

# GitHub (for scope refresh)
GITHUB_TOKEN=<gh-token>

# Deployment Configuration
AZURE_LOCATION=westeurope
SECURITY_EMAIL=kiliaan@bakerstreetproject.com
RESOURCE_GROUP=sec-bsp-rg-prod
```

### Optional
```bash
# qwe Notification
QWE_WEBHOOK=http://localhost:9001

# Budget Configuration
MONTHLY_BUDGET=100
BUDGET_CONTACT_EMAIL=kiliaan@bakerstreetproject.com
```

## Success Criteria

1. ✅ GitHub scopes automatically refresh before deployment
2. ✅ Azure providers register automatically with retry
3. ✅ Budgets configured with webhook notifications
4. ✅ Action groups route alerts to multiple channels
5. ✅ Runbooks execute auto-remediation
6. ✅ qwe notifications work in GitHub Actions
7. ✅ qwe notifications work in local orchestrator
8. ✅ Full deployment succeeds end-to-end
9. ✅ Validation confirms all components active

## Monitoring & Alerts

### Budget Alerts
- 50% threshold: Warning notification
- 75% threshold: Action group alert
- 90% threshold: Email + qwe notification
- 100% threshold: Critical alert + runbook

### Security Alerts
- Policy violations → Email + Runbook
- Public access detected → Block + Notify
- Defender recommendations → Daily summary
- Critical threats → Immediate action

### Deployment Alerts
- Deployment start → qwe notification
- Validation errors → Email + qwe
- Deployment success → All channels
- Deployment failure → Critical alert

## Next Actions

1. Implement GitHub scope refresh script
2. Create infrastructure Bicep modules
3. Enhance orchestrator with notifications
4. Test end-to-end automation flow
5. Deploy to production environment

---

**Last Updated**: December 6, 2025  
**Next Review**: After implementation completion
