# =================================================================
# Main Terraform Configuration - Datadog Demo Environment
# =================================================================
# This file orchestrates all infrastructure modules.
# Modules will be added incrementally and tested one by one.
# =================================================================

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Local variables
locals {
  account_id = data.aws_caller_identity.current.account_id
  azs        = slice(data.aws_availability_zones.available.names, 0, 2)
}

# =================================================================
# VPC Module - ACTIVE
# =================================================================
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = local.azs
  tags               = var.tags
}

# =================================================================
# EKS Module - ACTIVE
# =================================================================
module "eks" {
  source = "./modules/eks"

  depends_on = [module.vpc]

  cluster_name       = var.eks_cluster_name
  cluster_version    = var.eks_cluster_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  node_instance_type = var.eks_node_instance_type
  node_desired_size  = var.eks_node_desired_size
  node_min_size      = var.eks_node_min_size
  node_max_size      = var.eks_node_max_size
  aws_region         = var.aws_region
  tags               = var.tags
}

# =================================================================
# EC2 Module - ACTIVE
# =================================================================
module "ec2" {
  source = "./modules/ec2"

  depends_on = [module.vpc]

  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  public_subnet_ids       = module.vpc.public_subnet_ids
  private_subnet_ids      = module.vpc.private_subnet_ids
  ec2_instances           = var.ec2_instances
  key_name                = var.ec2_key_name
  ssh_allowed_cidr_blocks = var.ec2_ssh_allowed_cidr
  tags                    = var.tags
}

# =================================================================
# RDS Module - ACTIVE
# =================================================================
module "rds" {
  source = "./modules/rds"

  depends_on = [module.vpc]

  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  database_subnet_ids     = module.vpc.database_subnet_ids
  db_subnet_group_name    = module.vpc.db_subnet_group_name
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  engine_version          = var.rds_engine_version
  database_name           = var.rds_database_name
  master_username         = var.rds_master_username
  master_password         = var.rds_master_password
  backup_retention_period = var.rds_backup_retention_period
  backup_window           = var.rds_backup_window
  maintenance_window      = var.rds_maintenance_window
  multi_az                = var.rds_multi_az
  deletion_protection     = var.rds_deletion_protection
  tags                    = var.tags
}

# =================================================================
# ElastiCache Module - ACTIVE
# =================================================================
module "elasticache" {
  source = "./modules/elasticache"

  depends_on = [module.vpc]

  project_name             = var.project_name
  environment              = var.environment
  vpc_id                   = module.vpc.vpc_id
  cache_subnet_group_name  = module.vpc.elasticache_subnet_group_name
  allowed_cidr_blocks      = [var.vpc_cidr]
  node_type                = var.elasticache_node_type
  num_cache_nodes          = var.elasticache_num_cache_nodes
  engine_version           = var.elasticache_engine_version
  snapshot_retention_limit = var.elasticache_snapshot_retention_limit
  snapshot_window          = var.elasticache_snapshot_window
  maintenance_window       = "sun:06:00-sun:07:00"
  tags                     = var.tags
}

# =================================================================
# ALB Module - ACTIVE
# =================================================================
module "alb" {
  source = "./modules/alb"

  depends_on = [module.vpc]

  project_name        = var.project_name
  environment         = var.environment
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  allowed_cidr_blocks = var.alb_allowed_cidr
  enable_https        = var.alb_enable_https
  certificate_arn     = var.alb_certificate_arn
  tags                = var.tags
}
