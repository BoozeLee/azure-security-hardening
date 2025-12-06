#!/bin/bash
# Complete SaaS Platform Deployment Script
# Deploys security foundation + SaaS infrastructure

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🚀 Complete SaaS Platform Deployment                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI not found. Please install: https://aka.ms/azure-cli${NC}"
    exit 1
fi

if ! az account show &> /dev/null; then
    echo -e "${RED}❌ Not logged in to Azure. Run: az login${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites met${NC}"
echo ""

# Get parameters
read -p "Environment (prod/staging/dev) [prod]: " ENVIRONMENT
ENVIRONMENT=${ENVIRONMENT:-prod}

read -p "Location [westeurope]: " LOCATION
LOCATION=${LOCATION:-westeurope}

read -p "Security contact email: " SECURITY_EMAIL
if [[ -z "$SECURITY_EMAIL" ]]; then
    echo -e "${RED}❌ Security email is required${NC}"
    exit 1
fi

read -sp "SQL Admin Password: " SQL_PASSWORD
echo ""
if [[ -z "$SQL_PASSWORD" ]]; then
    echo -e "${RED}❌ SQL password is required${NC}"
    exit 1
fi

read -p "Enable SaaS components? (yes/no) [yes]: " ENABLE_SAAS
ENABLE_SAAS=${ENABLE_SAAS:-yes}

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}📋 Deployment Configuration:${NC}"
echo -e "   Environment: ${YELLOW}$ENVIRONMENT${NC}"
echo -e "   Location: ${YELLOW}$LOCATION${NC}"
echo -e "   Security Email: ${YELLOW}$SECURITY_EMAIL${NC}"
echo -e "   SaaS Components: ${YELLOW}$ENABLE_SAAS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

read -p "Proceed with deployment? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo -e "${YELLOW}Deployment cancelled${NC}"
    exit 0
fi

# Create deployment name
DEPLOYMENT_NAME="saas-platform-$(date +%Y%m%d-%H%M%S)"

echo ""
echo -e "${YELLOW}🚀 Starting deployment: $DEPLOYMENT_NAME${NC}"
echo ""

# Deploy infrastructure
az deployment sub create \
    --name "$DEPLOYMENT_NAME" \
    --location "$LOCATION" \
    --template-file infra/main-saas.bicep \
    --parameters \
        environmentName="$ENVIRONMENT" \
        location="$LOCATION" \
        securityContactEmail="$SECURITY_EMAIL" \
        sqlAdminLogin="sqladmin" \
        sqlAdminPassword="$SQL_PASSWORD" \
        enableSaaSComponents="$([ "$ENABLE_SAAS" = "yes" ] && echo true || echo false)"

# Check deployment status
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ Deployment Successful!                            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Get outputs
    echo -e "${BLUE}📊 Deployment Outputs:${NC}"
    az deployment sub show \
        --name "$DEPLOYMENT_NAME" \
        --query properties.outputs \
        --output table
    
    echo ""
    echo -e "${GREEN}🎉 Your SaaS platform is ready!${NC}"
    echo ""
    echo -e "${YELLOW}📝 Next Steps:${NC}"
    echo -e "   1. Configure custom domain in Front Door"
    echo -e "   2. Deploy application code to App Service"
    echo -e "   3. Run database migrations"
    echo -e "   4. Test API endpoints"
    echo -e "   5. Onboard first customer: ./scripts/saas-onboard-customer.sh"
    echo ""
else
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   ❌ Deployment Failed                                 ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Check the error messages above for details${NC}"
    exit 1
fi