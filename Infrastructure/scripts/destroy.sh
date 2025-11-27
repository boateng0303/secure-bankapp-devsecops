#!/bin/bash

# Script to destroy infrastructure
# Usage: ./destroy.sh <environment>

set -e

ENVIRONMENT=${1:-dev}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="${SCRIPT_DIR}/../environments/${ENVIRONMENT}"

if [ ! -d "${ENV_DIR}" ]; then
  echo "❌ Error: Environment '${ENVIRONMENT}' not found"
  echo "Available environments: dev, staging, prod"
  exit 1
fi

# Extra confirmation for production
if [ "${ENVIRONMENT}" == "prod" ]; then
  echo "⚠️  WARNING: You are about to destroy PRODUCTION infrastructure!"
  read -p "Type 'destroy-production' to confirm: " CONFIRM
  if [ "$CONFIRM" != "destroy-production" ]; then
    echo "❌ Destruction cancelled"
    exit 0
  fi
fi

echo "🗑️  Destroying infrastructure for ${ENVIRONMENT} environment..."

cd "${ENV_DIR}"

# Initialize
echo "📦 Initializing Terraform..."
terraform init

# Plan destroy
echo "📋 Creating destruction plan..."
terraform plan -destroy -out=tfplan-destroy

# Ask for confirmation
read -p "Do you want to proceed with destruction? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "❌ Destruction cancelled"
  exit 0
fi

# Destroy
echo "🔨 Destroying infrastructure..."
terraform apply tfplan-destroy

# Clean up plan file
rm -f tfplan-destroy

echo "✅ Infrastructure destroyed!"

