#!/bin/bash

# Legacy Admin App Deployment Script
# Deploys the application to EC2 VM1

set -e

# Configuration
EC2_USER="ec2-user"
EC2_HOST="18.197.114.70"  # VM1 public IP
SSH_KEY="/Users/luis.vazquez/.ssh/datadog-demo-key.pem"
APP_DIR="/home/ec2-user/legacy-admin"

echo "=== Legacy Admin App Deployment ==="
echo ""

# Check if SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    echo "Error: SSH key not found at $SSH_KEY"
    exit 1
fi

echo "Step 1: Creating application directory on EC2..."
ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} "mkdir -p ${APP_DIR}/templates"

echo "Step 2: Copying application files..."
scp -i "$SSH_KEY" app.py requirements.txt ${EC2_USER}@${EC2_HOST}:${APP_DIR}/

echo "Step 3: Copying templates..."
scp -i "$SSH_KEY" templates/index.html ${EC2_USER}@${EC2_HOST}:${APP_DIR}/templates/

echo "Step 4: Installing dependencies..."
ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} << 'ENDSSH'
cd /home/ec2-user/legacy-admin

# Install pip if not present
if ! command -v pip3 &> /dev/null; then
    sudo yum install -y python3-pip
fi

# Install application dependencies
pip3 install --user -r requirements.txt

echo "Dependencies installed successfully"
ENDSSH

echo "Step 5: Setting up systemd service..."
scp -i "$SSH_KEY" admin-app.service ${EC2_USER}@${EC2_HOST}:/tmp/

ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} << 'ENDSSH'
# Move service file and enable
sudo mv /tmp/admin-app.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable admin-app
sudo systemctl restart admin-app

echo "Service configured and started"
ENDSSH

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Checking service status..."
ssh -i "$SSH_KEY" ${EC2_USER}@${EC2_HOST} "sudo systemctl status admin-app --no-pager"

echo ""
echo "Application deployed successfully!"
echo "Access the admin dashboard at: http://${EC2_HOST}:5002"
echo ""
echo "Useful commands:"
echo "  View logs: ssh -i $SSH_KEY ${EC2_USER}@${EC2_HOST} 'sudo journalctl -u admin-app -f'"
echo "  Restart: ssh -i $SSH_KEY ${EC2_USER}@${EC2_HOST} 'sudo systemctl restart admin-app'"
echo "  Stop: ssh -i $SSH_KEY ${EC2_USER}@${EC2_HOST} 'sudo systemctl stop admin-app'"
