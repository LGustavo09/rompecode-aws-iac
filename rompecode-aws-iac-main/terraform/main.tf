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
    Project     = var.project_name
    Team        = "Los Rompe Codigo"
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
  admin_cidr           = var.admin_cidr
  asg_min_size         = var.asg_min_size
  asg_desired_capacity = var.asg_desired_capacity
  asg_max_size         = var.asg_max_size
  tags                 = local.common_tags
}
