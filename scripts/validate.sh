#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}
TERRAFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../terraform/environments/${ENVIRONMENT}" && pwd)"

if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "Error: Environment '$ENVIRONMENT' not found"
    exit 1
fi

cd "$TERRAFORM_DIR"

echo "Validating Terraform configuration for $ENVIRONMENT..."

echo "Checking Terraform installation..."
if ! command -v terraform &> /dev/null; then
    echo "Error: Terraform is not installed"
    exit 1
fi

echo "Running terraform init..."
terraform init -backend=false || true

echo "Running terraform validate..."
terraform validate

echo "Running terraform fmt..."
terraform fmt -recursive

echo "Running tflint..."
if command -v tflint &> /dev/null; then
    tflint --init
    tflint
fi

echo "Validation complete for $ENVIRONMENT"
