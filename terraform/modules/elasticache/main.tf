# =================================================================
# ElastiCache Redis Module
# =================================================================

# Security Group for ElastiCache
resource "aws_security_group" "redis" {
  name_prefix = "${var.project_name}-redis-"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  # Redis access from VPC
  ingress {
    description = "Redis from VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-redis-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Parameter Group for Redis optimization
resource "aws_elasticache_parameter_group" "redis" {
  name        = "${var.project_name}-redis7"
  family      = "redis7"
  description = "Custom parameter group for Redis 7"

  # Enable notifications for evictions (useful for Datadog monitoring)
  parameter {
    name  = "notify-keyspace-events"
    value = "Ex"
  }

  # Set max memory policy (evict least recently used keys when full)
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  # Timeout for idle connections (seconds)
  parameter {
    name  = "timeout"
    value = "300"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-redis7-params"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ElastiCache Redis Cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.project_name}-redis"
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  parameter_group_name = aws_elasticache_parameter_group.redis.name
  port                 = 6379

  # Network configuration
  subnet_group_name  = var.cache_subnet_group_name
  security_group_ids = [aws_security_group.redis.id]

  # Snapshot configuration
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = var.snapshot_window

  # Maintenance
  maintenance_window         = var.maintenance_window
  auto_minor_version_upgrade = true
  apply_immediately          = false

  # Notifications
  notification_topic_arn = var.sns_topic_arn

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-redis"
    }
  )
}
