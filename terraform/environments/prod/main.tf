variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

locals {
  common_tags = {
    Project     = "infra-provisioning"
    ManagedBy   = "terraform"
    Environment = var.environment
  }
}

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "infra-provisioning-tfstate"
    key    = "prod/terraform.tfstate"
    region = var.region
  }
}

module "networking" {
  source = "../../../modules/networking"

  environment        = var.environment
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  tags               = local.common_tags
}

module "compute" {
  source = "../../../modules/compute"

  environment       = var.environment
  instance_type     = "t3.large"
  instance_count    = 5
  subnet_ids        = module.networking.public_subnet_ids
  vpc_id            = module.networking.vpc_id
  tags              = local.common_tags
}

module "storage" {
  source = "../../../modules/storage"

  environment         = var.environment
  db_instance_class   = "db.r6g.large"
  db_allocated_storage = 100
  subnet_ids         = module.networking.private_subnet_ids
  security_group_id  = module.networking.security_group_id
  tags               = local.common_tags
}

output "lb_dns_name" {
  description = "Load balancer DNS name"
  value       = module.compute.lb_dns_name
}

output "db_endpoint" {
  description = "Database endpoint"
  value       = module.storage.db_endpoint
}
