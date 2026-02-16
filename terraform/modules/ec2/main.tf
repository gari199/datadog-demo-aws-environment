# =================================================================
# EC2 Module - Virtual Machines
# =================================================================

# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =================================================================
# Security Groups
# =================================================================

# Security Group for EC2 instances
resource "aws_security_group" "ec2" {
  name_prefix = "${var.project_name}-ec2-"
  description = "Security group for EC2 instances"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    description = "SSH from allowed CIDR blocks"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidr_blocks
  }

  # Legacy Admin App access (port 5002)
  ingress {
    description = "Legacy Admin App HTTP access"
    from_port   = 5002
    to_port     = 5002
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidr_blocks
  }

  # Allow all traffic from within VPC (for RDS, Redis, internal communication)
  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
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
      Name = "${var.project_name}-ec2-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# =================================================================
# IAM Role for EC2 (for SSM, CloudWatch, etc.)
# =================================================================

# IAM Role for EC2
resource "aws_iam_role" "ec2" {
  name_prefix = "${var.project_name}-ec2-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach SSM managed policy (for Systems Manager Session Manager)
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch agent policy
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name_prefix = "${var.project_name}-ec2-profile-"
  role        = aws_iam_role.ec2.name

  tags = var.tags
}

# =================================================================
# EC2 Instances
# =================================================================

resource "aws_instance" "main" {
  for_each = var.ec2_instances

  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = each.value.instance_type
  key_name      = var.key_name
  # vm1 (legacy-app-server) goes in public subnet, others in private
  subnet_id              = each.key == "vm1" ? var.public_subnet_ids[0] : var.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  # Assign public IP if in public subnet
  associate_public_ip_address = each.key == "vm1" ? true : false

  # User data script for initial setup
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    instance_name = each.value.name
    project_name  = var.project_name
  }))

  # Root volume
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true

    tags = merge(
      var.tags,
      {
        Name = "${var.project_name}-${each.value.name}-root"
      }
    )
  }

  # Enable detailed monitoring
  monitoring = true

  # Metadata options (IMDSv2 required for security)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${each.value.name}"
      Role = each.value.name
    }
  )

  lifecycle {
    ignore_changes = [
      ami, # Ignore AMI changes to prevent recreation on AMI updates
    ]
  }
}

# =================================================================
# Elastic IP for public instance (vm1 - app-server)
# =================================================================

resource "aws_eip" "vm1" {
  domain   = "vpc"
  instance = aws_instance.main["vm1"].id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-app-server-eip"
    }
  )

  depends_on = [aws_instance.main]
}
