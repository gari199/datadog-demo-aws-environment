# RDS Instance
output "instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.postgres.id
}

output "instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.postgres.arn
}

# Connection details
output "endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = aws_db_instance.postgres.endpoint
}

output "address" {
  description = "RDS instance address (hostname only)"
  value       = aws_db_instance.postgres.address
}

output "port" {
  description = "RDS instance port"
  value       = aws_db_instance.postgres.port
}

# Database details
output "database_name" {
  description = "Database name"
  value       = aws_db_instance.postgres.db_name
}

output "master_username" {
  description = "Master username"
  value       = aws_db_instance.postgres.username
}

# Security group
output "security_group_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds.id
}

# Connection string
output "connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = "postgresql://${aws_db_instance.postgres.username}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}"
}

# Availability zone
output "availability_zone" {
  description = "Availability zone of the RDS instance"
  value       = aws_db_instance.postgres.availability_zone
}

# Multi-AZ status
output "multi_az" {
  description = "Whether the RDS instance is multi-AZ"
  value       = aws_db_instance.postgres.multi_az
}
