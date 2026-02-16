# Instance IDs
output "instance_ids" {
  description = "Map of instance IDs"
  value       = { for k, v in aws_instance.main : k => v.id }
}

# Private IPs
output "private_ips" {
  description = "Map of private IP addresses"
  value       = { for k, v in aws_instance.main : k => v.private_ip }
}

# Instance details
output "instances" {
  description = "Full instance details"
  value       = aws_instance.main
}

# Security Group ID
output "security_group_id" {
  description = "Security group ID for EC2 instances"
  value       = aws_security_group.ec2.id
}

# Public IPs
output "public_ips" {
  description = "Map of public IP addresses (only for instances in public subnet)"
  value = {
    vm1 = aws_eip.vm1.public_ip
  }
}

# SSH commands
output "ssh_info" {
  description = "SSH connection information"
  value = {
    vm1 = {
      instance_id = aws_instance.main["vm1"].id
      private_ip  = aws_instance.main["vm1"].private_ip
      public_ip   = aws_eip.vm1.public_ip
      ssh_command = "ssh -i ~/.ssh/datadog-demo-key.pem ec2-user@${aws_eip.vm1.public_ip}"
      note        = "Direct SSH access via public IP"
    }
    vm2 = {
      instance_id = aws_instance.main["vm2"].id
      private_ip  = aws_instance.main["vm2"].private_ip
      public_ip   = null
      ssh_command = "ssh -i ~/.ssh/datadog-demo-key.pem -J ec2-user@${aws_eip.vm1.public_ip} ec2-user@${aws_instance.main["vm2"].private_ip}"
      note        = "SSH via vm1 as jump host (ProxyJump)"
    }
  }
}

# IAM Role
output "iam_role_name" {
  description = "IAM role name for EC2 instances"
  value       = aws_iam_role.ec2.name
}

output "iam_role_arn" {
  description = "IAM role ARN for EC2 instances"
  value       = aws_iam_role.ec2.arn
}
