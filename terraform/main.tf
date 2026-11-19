############################################
# Root module - Los Rompe Código
# Orquesta los módulos de red (vpc) y cómputo (compute)
############################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = "IaC-Challenge"
    Team        = "Los Rompe Codigos"
    Environment = var.environment
  }
}

module "vpc" {
  source = "./modules/vpc"

  project              = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = local.common_tags
}

module "compute" {
  source = "./modules/compute"

  project              = var.project_name
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.vpc.public_subnet_ids
  private_subnet_ids   = module.vpc.private_subnet_ids
  instance_type        = var.instance_type
  asg_min_size         = var.asg_min_size
  asg_desired_capacity = var.asg_desired_capacity
  asg_max_size         = var.asg_max_size
  tags                 = local.common_tags
}

resource "aws_s3_bucket" "ansible_transfer" {
  bucket_prefix = "${var.project_name}-ssm-"
}

resource "aws_s3_bucket_public_access_block" "ansible_transfer" {
  bucket                  = aws_s3_bucket.ansible_transfer.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "ansible_transfer" {
  bucket = aws_s3_bucket.ansible_transfer.id
  rule {
    id     = "expire-transfers"
    status = "Enabled"
    filter {}
    expiration {
      days = 1
    }
  }
}

output "ansible_transfer_bucket" {
  description = "Bucket privado para transferencias de Ansible por SSM"
  value       = aws_s3_bucket.ansible_transfer.bucket
}
