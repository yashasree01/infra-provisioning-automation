#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}
ACTION=${2:-plan}
TERRAFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../terraform/environments/${ENVIRONMENT}" && pwd)"

if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "Error: Environment '$ENVIRONMENT' not found"
    exit 1
fi

cd "$TERRAFORM_DIR"

echo "Deploying infrastructure for $ENVIRONMENT environment..."

case "$ACTION" in
    plan)
        echo "Running terraform plan..."
        terraform plan -out=tfplan
        echo "Plan saved to tfplan"
        ;;
    apply)
        echo "Running terraform apply..."
        if [ -f tfplan ]; then
            terraform apply tfplan
        else
            terraform apply
        fi
        ;;
    destroy)
        read -p "Are you sure you want to destroy $ENVIRONMENT resources? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            echo "Running terraform destroy..."
            terraform destroy
        else
            echo "Aborted"
            exit 0
        fi
        ;;
    *)
        echo "Usage: $0 <environment> <plan|apply|destroy>"
        exit 1
        ;;
esac

echo "Deployment complete for $ENVIRONMENT"
