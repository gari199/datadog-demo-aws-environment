# =================================================================
# Terraform Outputs - Datadog Demo Environment
# =================================================================
# Outputs will be added incrementally as modules are deployed
# =================================================================

# General Information
output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = local.account_id
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

# =================================================================
# VPC Outputs - ACTIVE
# =================================================================
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = module.vpc.database_subnet_ids
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = module.vpc.nat_gateway_ids
}

# =================================================================
# EKS Outputs - ACTIVE
# =================================================================
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = module.eks.cluster_version
}

output "eks_cluster_security_group_id" {
  description = "Security group ID for EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_security_group_id" {
  description = "Security group ID for EKS nodes"
  value       = module.eks.node_security_group_id
}

output "eks_configure_kubectl" {
  description = "Command to configure kubectl"
  value       = module.eks.configure_kubectl_command
}

output "eks_node_group_status" {
  description = "Status of EKS node group"
  value       = module.eks.node_group_status
}

# =================================================================
# EC2 Outputs - ACTIVE
# =================================================================
output "ec2_instance_ids" {
  description = "EC2 instance IDs"
  value       = module.ec2.instance_ids
}

output "ec2_private_ips" {
  description = "EC2 private IP addresses"
  value       = module.ec2.private_ips
}

output "ec2_public_ips" {
  description = "EC2 public IP addresses"
  value       = module.ec2.public_ips
}

output "ec2_ssh_info" {
  description = "SSH connection information for EC2 instances"
  value       = module.ec2.ssh_info
  sensitive   = false
}

output "ec2_security_group_id" {
  description = "Security group ID for EC2 instances"
  value       = module.ec2.security_group_id
}

# =================================================================
# RDS Outputs - ACTIVE
# =================================================================
output "rds_endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = module.rds.endpoint
}

output "rds_address" {
  description = "RDS instance address (hostname only)"
  value       = module.rds.address
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.rds.database_name
}

output "rds_master_username" {
  description = "RDS master username"
  value       = module.rds.master_username
}

output "rds_connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = module.rds.connection_string
}

output "rds_security_group_id" {
  description = "Security group ID for RDS"
  value       = module.rds.security_group_id
}

output "rds_connect_command" {
  description = "psql command to connect to RDS"
  value       = "psql -h ${module.rds.address} -U ${module.rds.master_username} -d ${module.rds.database_name}"
}

# =================================================================
# ElastiCache Outputs - ACTIVE
# =================================================================
output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = module.elasticache.endpoint
}

output "redis_port" {
  description = "ElastiCache Redis port"
  value       = module.elasticache.port
}

output "redis_connection_string" {
  description = "Redis connection string"
  value       = module.elasticache.connection_string
}

output "redis_security_group_id" {
  description = "Security group ID for Redis"
  value       = module.elasticache.security_group_id
}

output "redis_connect_command" {
  description = "redis-cli command to connect to Redis"
  value       = "redis-cli -h ${module.elasticache.endpoint} -p ${module.elasticache.port}"
}

# =================================================================
# ALB Outputs - ACTIVE
# =================================================================
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "alb_url" {
  description = "ALB URL"
  value       = module.alb.alb_url
}

output "alb_zone_id" {
  description = "ALB hosted zone ID"
  value       = module.alb.alb_zone_id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = module.alb.alb_arn
}

output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = module.alb.security_group_id
}

output "alb_default_target_group_arn" {
  description = "Default target group ARN"
  value       = module.alb.default_target_group_arn
}
