variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for the region"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "project_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "networking" {
  source = "./terraform/modules/networking"

  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  tags                = var.project_tags
}

module "compute" {
  source = "./terraform/modules/compute"

  environment       = var.environment
  subnet_ids        = module.networking.public_subnet_ids
  vpc_id            = module.networking.vpc_id
  tags              = var.project_tags
}

module "storage" {
  source = "./terraform/modules/storage"

  environment = var.environment
  tags        = var.project_tags
}
