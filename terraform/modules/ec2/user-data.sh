#!/bin/bash
# =================================================================
# EC2 User Data Script - Initial Setup
# =================================================================
# This script runs on first boot of EC2 instances
# Instance: ${instance_name}
# Project: ${project_name}
# =================================================================

set -e

# Update system
yum update -y

# Install essential packages
yum install -y \
    git \
    wget \
    curl \
    vim \
    htop \
    tmux \
    jq \
    nc \
    telnet \
    bind-utils \
    postgresql15 \
    redis6

# Install Docker (for potential future use)
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Python 3.9
amazon-linux-extras install python3.8 -y
pip3 install --upgrade pip

# Install useful Python packages
pip3 install \
    boto3 \
    requests \
    psycopg2-binary \
    redis

# Install AWS CLI v2 (latest)
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install Session Manager plugin (for AWS SSM)
yum install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm

# Set hostname
hostnamectl set-hostname ${instance_name}

# Create a welcome message
cat > /etc/motd << 'EOF'
=========================================
  Datadog Demo Environment
  Instance: ${instance_name}
  Project: ${project_name}
=========================================

Installed tools:
  - Docker
  - PostgreSQL client (psql)
  - Redis client (redis-cli)
  - AWS CLI v2
  - Python 3 with boto3, psycopg2, redis
  - Standard utilities (git, curl, jq, etc.)

Quick commands:
  - Check VPC: ip addr | grep 10.0
  - Test RDS: psql -h <rds-endpoint> -U dbadmin -d ecommerce
  - Test Redis: redis-cli -h <redis-endpoint>
  - AWS Region: aws configure get region

EOF

# Configure AWS CLI default region
mkdir -p /home/ec2-user/.aws
cat > /home/ec2-user/.aws/config << EOF
[default]
region = eu-central-1
output = json
EOF
chown -R ec2-user:ec2-user /home/ec2-user/.aws

# Create directory for application deployment
mkdir -p /opt/app
chown -R ec2-user:ec2-user /opt/app

# Enable and start CloudWatch agent (if needed later)
# amazon-cloudwatch-agent will be configured in Phase 4 with Datadog

# Log completion
echo "User data script completed at $(date)" >> /var/log/user-data.log

# Signal completion
echo "EC2 instance ${instance_name} is ready!" >> /var/log/user-data.log
