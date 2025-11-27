#!/bin/bash

# Script to create S3 bucket and DynamoDB table for Terraform state backend
# Usage: ./setup-backend.sh <environment> <region>

set -e

ENVIRONMENT=${1:-dev}
REGION=${2:-us-east-1}
BUCKET_NAME="banking-app-terraform-state-${ENVIRONMENT}"
DYNAMODB_TABLE="terraform-state-lock-${ENVIRONMENT}"

echo "Setting up Terraform backend for ${ENVIRONMENT} environment in ${REGION}..."

# Create S3 bucket
echo "Creating S3 bucket: ${BUCKET_NAME}..."
aws s3api create-bucket \
  --bucket ${BUCKET_NAME} \
  --region ${REGION} \
  --create-bucket-configuration LocationConstraint=${REGION} 2>/dev/null || echo "Bucket already exists"

# Enable versioning
echo "Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
  --bucket ${BUCKET_NAME} \
  --versioning-configuration Status=Enabled \
  --region ${REGION}

# Enable encryption
echo "Enabling encryption on S3 bucket..."
aws s3api put-bucket-encryption \
  --bucket ${BUCKET_NAME} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }' \
  --region ${REGION}

# Block public access
echo "Blocking public access on S3 bucket..."
aws s3api put-public-access-block \
  --bucket ${BUCKET_NAME} \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
  --region ${REGION}

# Create DynamoDB table for state locking
echo "Creating DynamoDB table: ${DYNAMODB_TABLE}..."
aws dynamodb create-table \
  --table-name ${DYNAMODB_TABLE} \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ${REGION} 2>/dev/null || echo "Table already exists"

echo "✅ Backend setup complete!"
echo "Bucket: ${BUCKET_NAME}"
echo "DynamoDB Table: ${DYNAMODB_TABLE}"

