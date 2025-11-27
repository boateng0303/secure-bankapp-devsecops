#!/bin/bash

# Script to deploy infrastructure
# Usage: ./deploy.sh <environment>

set -e

ENVIRONMENT=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="${SCRIPT_DIR}/../environments/${ENVIRONMENT}"

if [ ! -d "${ENV_DIR}" ]; then
  echo "❌ Error: Environment '${ENVIRONMENT}' not found"
  echo "Available environments: dev, staging, prod"
  exit 1
fi

echo "🚀 Deploying infrastructure for ${ENVIRONMENT} environment..."

cd "${ENV_DIR}"

# Check if backend is configured
echo "📦 Initializing Terraform..."
terraform init

# Validate configuration
echo "✅ Validating Terraform configuration..."
terraform validate

# Plan
echo "📋 Creating Terraform plan..."
terraform plan -out=tfplan

# Ask for confirmation
read -p "Do you want to apply this plan? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "❌ Deployment cancelled"
  exit 0
fi

# Apply
echo "🔨 Applying Terraform configuration..."
terraform apply tfplan

# Clean up plan file
rm -f tfplan

echo "✅ Deployment complete!"
echo ""
echo "📝 Next steps:"
echo "1. Configure kubectl:"
terraform output -raw configure_kubectl
echo ""
echo "2. Get database credentials:"
echo "   aws secretsmanager get-secret-value --secret-id \$(terraform output -raw db_secret_arn) --query SecretString --output text | jq ."

