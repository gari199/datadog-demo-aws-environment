# AWS Datadog Demo Environment

A comprehensive AWS environment designed to showcase all Datadog capabilities for sales demonstrations and testing.

## Overview

This project creates a production-like AWS environment with:
- **2 EC2 VMs**: Legacy application server + Utility server
- **1 EKS Cluster**: Kubernetes cluster with 4 microservices (2 t3.small nodes)
- **Supporting Services**: RDS PostgreSQL, ElastiCache Redis, Application Load Balancer

## Architecture

```
Internet
    ↓
Application Load Balancer
    ├── EC2 VM 1: Legacy Python/Flask Admin App → RDS PostgreSQL
    ├── EC2 VM 2: Utility Server (background jobs, security monitoring)
    └── EKS Cluster (2 t3.small nodes):
        ├── Frontend Pod (Node.js/Express + Vanilla JS) - RUM, Session Replay
        ├── API Gateway Pod (Node.js/Express) - APM orchestration
        ├── Order Service Pod (Python/Flask) - APM, custom metrics, DBM
        └── Payment Service Pod (Go/Gin) - APM, Security (ASM)
```

## Datadog Features Demonstrated

- **APM (Application Performance Monitoring)**: Distributed tracing across 4 services in 3 languages
- **RUM & Session Replay**: Real user monitoring and session recordings
- **Logs**: Centralized logging with trace correlation
- **Infrastructure Monitoring**: VM and container monitoring
- **Database Monitoring**: RDS PostgreSQL query performance
- **Security Monitoring**: ASM (Application Security) + CWS (Cloud Workload Security)
- **Synthetics**: API and browser tests
- **Custom Metrics**: Business KPIs via StatsD

## Tech Stack

- **IaC**: Terraform
- **Container Orchestration**: Amazon EKS (Kubernetes 1.32)
- **Languages**: Python, Node.js, Go, Vanilla JavaScript
- **Database**: PostgreSQL 16.6 (RDS)
- **Cache**: Redis 7.0 (ElastiCache)
- **Load Balancer**: AWS Application Load Balancer

## Current Implementation Status

| Phase | Focus | Status |
|-------|-------|--------|
| **Phase 1** | Folder Structure | ✅ Complete |
| **Phase 2** | Infrastructure | ✅ Complete |
| **Phase 3** | Applications | ✅ Complete |
| **Phase 4** | Datadog | ⏳ Pending |

---

## Complete Deployment Guide

Follow these steps to deploy the entire environment from scratch.

### Prerequisites

Before you begin, ensure you have:

#### 1. AWS Account with Permissions

You need an AWS account with permissions to create:
- VPC, Subnets, Internet Gateway, NAT Gateway
- EKS Cluster and Node Groups
- EC2 Instances
- RDS Database Instances
- ElastiCache Clusters
- Application Load Balancer
- IAM Roles and Policies
- Security Groups

#### 2. Required Tools Installed

```bash
# Verify installations
aws --version          # AWS CLI >= 2.0
terraform --version    # Terraform >= 1.0
kubectl version        # kubectl >= 1.27
```

**Installation Links:**
- AWS CLI: https://aws.amazon.com/cli/
- Terraform: https://www.terraform.io/downloads
- kubectl: https://kubernetes.io/docs/tasks/tools/

#### 3. AWS CLI Configured

```bash
# Option 1: Standard AWS credentials
aws configure

# Option 2: AWS SSO (recommended)
aws configure sso
aws sso login
```

Verify your credentials work:
```bash
aws sts get-caller-identity
```

#### 4. SSH Key Pair (Required for EC2 Access)

Create an SSH key pair in AWS:

```bash
# Option A: Create via AWS CLI
aws ec2 create-key-pair \
  --key-name datadog-demo-key \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/datadog-demo-key.pem

chmod 400 ~/.ssh/datadog-demo-key.pem

# Option B: Create via AWS Console
# 1. Go to EC2 > Key Pairs > Create Key Pair
# 2. Name: datadog-demo-key
# 3. Download and save to ~/.ssh/datadog-demo-key.pem
# 4. Run: chmod 400 ~/.ssh/datadog-demo-key.pem
```

#### 5. Clone This Repository

```bash
git clone <repository-url>
cd aws-env
```

#### 6. Docker Images

All Docker images are **publicly available** - no authentication needed.
- Images are pre-built and hosted in a public registry
- No need to build images locally

---

## Step-by-Step Deployment

### Step 1: Configure Terraform Variables

1. Navigate to the terraform directory:
   ```bash
   cd terraform
   ```

2. Create your `terraform.tfvars` file with your configuration:

   ```bash
   cat > terraform.tfvars << 'EOF'
   # ============================================
   # AWS Configuration
   # ============================================
   aws_region = "eu-central-1"  # Change to your preferred region

   # ============================================
   # Project Information
   # ============================================
   project_name = "datadog-demo"
   environment  = "demo"

   # ============================================
   # VPC Configuration
   # ============================================
   vpc_cidr = "10.0.0.0/16"

   # IMPORTANT: Update availability zones for your region
   # eu-central-1: ["eu-central-1a", "eu-central-1b"]
   # us-east-1: ["us-east-1a", "us-east-1b"]
   # us-west-2: ["us-west-2a", "us-west-2b"]
   availability_zones = ["eu-central-1a", "eu-central-1b"]

   # ============================================
   # EKS Configuration
   # ============================================
   eks_cluster_name        = "datadog-demo-cluster"
   eks_cluster_version     = "1.32"
   eks_node_instance_type  = "t3.small"
   eks_node_desired_size   = 2
   eks_node_min_size       = 2
   eks_node_max_size       = 3

   # ============================================
   # EC2 Configuration
   # ============================================
   ec2_instances = {
     vm1 = {
       name          = "app-server"
       instance_type = "t3.small"
       ami_type      = "amazon-linux-2"
     }
     vm2 = {
       name          = "utility-server"
       instance_type = "t3.micro"
       ami_type      = "amazon-linux-2"
     }
   }

   ec2_key_name = "datadog-demo-key"  # Must match the key you created in Prerequisites

   # ============================================
   # RDS PostgreSQL Configuration
   # ============================================
   rds_instance_class    = "db.t3.micro"
   rds_database_name     = "ecommerce"
   rds_master_username   = "dbadmin"
   rds_master_password   = "ChangeMe123!SecurePassword"  # CHANGE THIS!

   # ============================================
   # ElastiCache Redis Configuration
   # ============================================
   elasticache_node_type = "cache.t3.micro"

   # ============================================
   # Tags
   # ============================================
   tags = {
     Project     = "datadog-demo"
     Environment = "demo"
     ManagedBy   = "terraform"
   }
   EOF
   ```

3. **IMPORTANT**: Edit the file and update these values:
   ```bash
   nano terraform.tfvars  # or use your preferred editor
   ```

   **Required changes:**
   - `aws_region`: Your preferred AWS region
   - `availability_zones`: Must match your region (check AWS console)
   - `rds_master_password`: Use a strong, unique password
   - `ec2_key_name`: Must match the SSH key you created in Prerequisites

---

### Step 2: Deploy Infrastructure with Terraform

⏱️ **Expected Time**: 15-20 minutes

1. Initialize Terraform (download providers and modules):
   ```bash
   terraform init
   ```

   You should see "Terraform has been successfully initialized!"

2. Review what will be created:
   ```bash
   terraform plan -out=tfplan
   ```

   This will show you:
   - ~50+ resources to be created
   - VPC with subnets, NAT gateways, Internet gateway
   - EKS cluster with 2 worker nodes
   - 2 EC2 instances
   - RDS PostgreSQL database
   - ElastiCache Redis cluster
   - Application Load Balancer
   - Security groups and IAM roles

   Review the plan carefully before proceeding.

3. Deploy the infrastructure:
   ```bash
   terraform apply tfplan
   ```

   Type `yes` when prompted to confirm.

   **What's happening:**
   - VPC creation: 1-2 minutes
   - EKS cluster: 10-12 minutes (this is the longest step)
   - RDS database: 5-7 minutes
   - Other resources: 2-3 minutes

   ☕ Grab a coffee - this will take 15-20 minutes total.

4. Once complete, save the outputs:
   ```bash
   terraform output > ../infrastructure-outputs.txt
   cat ../infrastructure-outputs.txt
   ```

   You should see endpoints for RDS, Redis, EC2 IPs, EKS cluster info, etc.

5. Verify infrastructure was created:
   ```bash
   # Check VPC
   aws ec2 describe-vpcs --filters "Name=tag:Project,Values=datadog-demo" --query 'Vpcs[0].VpcId'

   # Check EKS cluster
   aws eks describe-cluster --name datadog-demo-cluster --query 'cluster.status'

   # Check EC2 instances
   aws ec2 describe-instances --filters "Name=tag:Project,Values=datadog-demo" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],PublicIpAddress]' --output table
   ```

---

### Step 3: Configure kubectl for EKS

1. Update your kubeconfig to connect to the EKS cluster:
   ```bash
   aws eks update-kubeconfig --name datadog-demo-cluster --region $(terraform output -raw aws_region)
   ```

   You should see: "Added new context arn:aws:eks:..."

2. Verify connectivity to the cluster:
   ```bash
   kubectl get nodes
   ```

   You should see 2 nodes in "Ready" status:
   ```
   NAME                                          STATUS   ROLES    AGE   VERSION
   ip-10-0-10-xxx.region.compute.internal       Ready    <none>   5m    v1.32.x
   ip-10-0-11-xxx.region.compute.internal       Ready    <none>   5m    v1.32.x
   ```

   If you don't see nodes, wait a few minutes and try again.

3. Check cluster info:
   ```bash
   kubectl cluster-info
   kubectl get namespaces
   ```

---

### Step 4: Deploy Kubernetes Applications

1. Navigate back to project root:
   ```bash
   cd ..  # Move back to aws-env directory
   pwd    # Should show /path/to/aws-env
   ```

2. Create the Kubernetes namespace:
   ```bash
   kubectl apply -f kubernetes/base/namespace.yaml
   ```

   Verify:
   ```bash
   kubectl get namespace datadog-demo
   ```

3. Get database and Redis endpoints from Terraform:
   ```bash
   cd terraform

   # Get RDS endpoint (hostname only, without port)
   export DB_HOST=$(terraform output -raw rds_address)
   export DB_PORT="5432"
   export DB_NAME=$(terraform output -raw rds_database_name)
   export DB_USER=$(terraform output -raw rds_master_username)

   # Get Redis endpoint (hostname only, without port)
   export REDIS_HOST=$(terraform output -raw redis_endpoint | cut -d: -f1)
   export REDIS_PORT="6379"

   # Display values to verify
   echo "DB_HOST: $DB_HOST"
   echo "REDIS_HOST: $REDIS_HOST"

   cd ..
   ```

4. Create ConfigMap with database connection info:
   ```bash
   kubectl create configmap app-config -n datadog-demo \
     --from-literal=DB_HOST="$DB_HOST" \
     --from-literal=DB_PORT="$DB_PORT" \
     --from-literal=DB_NAME="$DB_NAME" \
     --from-literal=DB_USER="$DB_USER" \
     --from-literal=REDIS_HOST="$REDIS_HOST" \
     --from-literal=REDIS_PORT="$REDIS_PORT"
   ```

   Verify:
   ```bash
   kubectl get configmap app-config -n datadog-demo -o yaml
   ```

5. Create Secret with database password:
   ```bash
   # Use the SAME password you set in terraform.tfvars
   kubectl create secret generic app-secrets -n datadog-demo \
     --from-literal=DB_PASSWORD='ChangeMe123!SecurePassword'
   ```

   **IMPORTANT**: Replace `ChangeMe123!SecurePassword` with your actual password from terraform.tfvars!

   Verify (this will show the secret exists but not the value):
   ```bash
   kubectl get secret app-secrets -n datadog-demo
   ```

6. Deploy all microservices to Kubernetes:
   ```bash
   kubectl apply -f kubernetes/apps/
   ```

   This deploys:
   - Frontend (Node.js)
   - API Gateway (Node.js)
   - Order Service (Python)
   - Payment Service (Go)

7. Wait for pods to be ready (this may take 2-5 minutes):
   ```bash
   kubectl get pods -n datadog-demo -w
   ```

   Wait until all pods show `1/1` in the READY column and `Running` status:
   ```
   NAME                               READY   STATUS    RESTARTS   AGE
   api-gateway-xxx-yyy                1/1     Running   0          2m
   api-gateway-xxx-zzz                1/1     Running   0          2m
   frontend-xxx-yyy                   1/1     Running   0          2m
   frontend-xxx-zzz                   1/1     Running   0          2m
   order-service-xxx-yyy              1/1     Running   0          2m
   order-service-xxx-zzz              1/1     Running   0          2m
   payment-service-xxx-yyy            1/1     Running   0          2m
   payment-service-xxx-zzz            1/1     Running   0          2m
   ```

   Press `Ctrl+C` to exit watch mode.

   **Troubleshooting**: If pods are stuck in `Pending` or `ImagePullBackOff`:
   ```bash
   # Check pod details
   kubectl describe pod <pod-name> -n datadog-demo

   # Check events
   kubectl get events -n datadog-demo --sort-by='.lastTimestamp'
   ```

8. Verify services are created:
   ```bash
   kubectl get svc -n datadog-demo
   ```

   You should see 4 services (all ClusterIP type):
   ```
   NAME              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
   api-gateway       ClusterIP   172.20.x.x       <none>        80/TCP    3m
   frontend          ClusterIP   172.20.x.x       <none>        80/TCP    3m
   order-service     ClusterIP   172.20.x.x       <none>        80/TCP    3m
   payment-service   ClusterIP   172.20.x.x       <none>        80/TCP    3m
   ```

---

### Step 5: Deploy Legacy Admin App to EC2

The legacy admin application runs directly on EC2 (VM1) to demonstrate monitoring of traditional infrastructure alongside containerized apps.

1. Get VM1 public IP:
   ```bash
   cd terraform
   VM1_IP=$(terraform output -json ec2_public_ips | jq -r '.vm1')
   echo "VM1 Public IP: $VM1_IP"
   cd ..
   ```

2. SSH to VM1:
   ```bash
   ssh -i ~/.ssh/datadog-demo-key.pem ec2-user@$VM1_IP
   ```

   If you get a "Host key verification" prompt, type `yes`.

   **Troubleshooting SSH issues:**
   - Permission denied: Check `chmod 400 ~/.ssh/datadog-demo-key.pem`
   - Connection timeout: Check security group allows SSH from your IP
   - Wrong key: Verify `ec2_key_name` in terraform.tfvars matches your key

3. Once connected to VM1, install dependencies:
   ```bash
   # Update system packages
   sudo yum update -y

   # Install Python 3 and required tools
   sudo yum install -y python3 python3-pip git postgresql15

   # Verify installations
   python3 --version
   pip3 --version
   ```

4. Clone the repository on EC2:
   ```bash
   cd ~
   git clone <repository-url> aws-env
   cd aws-env/applications/legacy-admin
   ```

   **Alternative**: If repository is private, you can use `scp` to copy files:
   ```bash
   # From your local machine (new terminal):
   scp -i ~/.ssh/datadog-demo-key.pem -r applications/legacy-admin ec2-user@$VM1_IP:~/
   ```

5. Install Python dependencies:
   ```bash
   cd ~/aws-env/applications/legacy-admin
   pip3 install --user -r requirements.txt
   ```

6. Create environment configuration file:
   ```bash
   # Get DB endpoint from Terraform (from your local machine)
   cd terraform
   DB_ENDPOINT=$(terraform output -raw rds_address)
   echo "DB Endpoint: $DB_ENDPOINT"
   ```

   Then back on EC2:
   ```bash
   cat > .env << 'EOF'
   DB_HOST=<paste-db-endpoint-here>
   DB_PORT=5432
   DB_NAME=ecommerce
   DB_USER=dbadmin
   DB_PASSWORD=ChangeMe123!SecurePassword
   PORT=5002
   EOF
   ```

   **IMPORTANT**: Replace values:
   - `<paste-db-endpoint-here>`: Your RDS endpoint
   - `ChangeMe123!SecurePassword`: Your actual database password

   Verify the file:
   ```bash
   cat .env
   ```

7. Test the application manually first:
   ```bash
   python3 app.py
   ```

   You should see:
   ```
   * Running on http://0.0.0.0:5002
   ```

   Press `Ctrl+C` to stop it. If it works, proceed to create a service.

8. Create systemd service for automatic startup:
   ```bash
   sudo tee /etc/systemd/system/legacy-admin.service > /dev/null << EOF
   [Unit]
   Description=Legacy Admin Application
   After=network.target

   [Service]
   Type=simple
   User=ec2-user
   WorkingDirectory=/home/ec2-user/aws-env/applications/legacy-admin
   Environment="PATH=/usr/local/bin:/usr/bin:/bin:/home/ec2-user/.local/bin"
   EnvironmentFile=/home/ec2-user/aws-env/applications/legacy-admin/.env
   ExecStart=/usr/bin/python3 app.py
   Restart=always
   RestartSec=10

   [Install]
   WantedBy=multi-user.target
   EOF
   ```

9. Start and enable the service:
   ```bash
   # Reload systemd
   sudo systemctl daemon-reload

   # Enable service to start on boot
   sudo systemctl enable legacy-admin

   # Start the service
   sudo systemctl start legacy-admin

   # Check status
   sudo systemctl status legacy-admin
   ```

   You should see "active (running)" in green.

10. View logs to verify it's working:
    ```bash
    sudo journalctl -u legacy-admin -f
    ```

    Press `Ctrl+C` to exit.

11. Test the admin app from your local machine:
    ```bash
    curl http://$VM1_IP:5002/health
    ```

    You should get a JSON response with service status.

12. Exit from EC2:
    ```bash
    exit
    ```

---

### Step 6: Verify Complete Deployment

Run these verification steps from your local machine:

#### 1. Check Kubernetes Pods
```bash
kubectl get pods -n datadog-demo
```

All pods should show `1/1 Running`.

#### 2. Test Pod Health Endpoints
```bash
# Test frontend
kubectl exec -n datadog-demo deployment/frontend -- curl -s http://localhost:8080/health

# Test API gateway
kubectl exec -n datadog-demo deployment/api-gateway -- curl -s http://localhost:3000/health

# Test order service
kubectl exec -n datadog-demo deployment/order-service -- curl -s http://localhost:5000/health

# Test payment service
kubectl exec -n datadog-demo deployment/payment-service -- curl -s http://localhost:5001/health
```

All should return JSON with `"status": "healthy"`.

#### 3. Test Service Communication
```bash
# Test that frontend can reach API gateway
kubectl exec -n datadog-demo deployment/frontend -- curl -s http://api-gateway/api/products

# Test that API gateway can reach order service
kubectl exec -n datadog-demo deployment/api-gateway -- curl -s http://order-service/health
```

#### 4. Check Database Connectivity
```bash
# From a pod, test database connection
kubectl run postgres-test -n datadog-demo --rm -it --image=postgres:16 --restart=Never -- \
  psql -h $(cd terraform && terraform output -raw rds_address) -U dbadmin -d ecommerce -c "\dt"
```

Enter the database password when prompted. You should see database tables (or "No relations found" if tables haven't been created yet).

#### 5. Check Legacy Admin App
```bash
# Get VM1 IP
cd terraform
VM1_IP=$(terraform output -json ec2_public_ips | jq -r '.vm1')

# Test health endpoint
curl http://$VM1_IP:5002/health

# Check if it can connect to database
curl http://$VM1_IP:5002/
```

#### 6. View All Infrastructure Status
```bash
# Kubernetes resources
kubectl get all -n datadog-demo

# Terraform outputs
cd terraform
terraform output

# AWS resources
aws eks describe-cluster --name datadog-demo-cluster --query 'cluster.status'
aws rds describe-db-instances --db-instance-identifier datadog-demo-postgres --query 'DBInstances[0].DBInstanceStatus'
```

---

### Step 7: Access the Applications

#### Option A: Port Forwarding (Recommended for Testing)

1. **Access Frontend (E-Commerce Store):**
   ```bash
   # Start port forwarding (runs in foreground)
   kubectl port-forward -n datadog-demo svc/frontend 8080:80
   ```

   Keep this terminal open. Open your browser:
   - **URL**: http://localhost:8080

   You should see the e-commerce store with products.

   To run in background:
   ```bash
   kubectl port-forward -n datadog-demo svc/frontend 8080:80 > /dev/null 2>&1 &
   ```

2. **Access API Gateway (Optional):**
   ```bash
   # In a new terminal
   kubectl port-forward -n datadog-demo svc/api-gateway 3000:80
   ```

   Test API endpoints:
   ```bash
   curl http://localhost:3000/api/products
   curl http://localhost:3000/health
   ```

3. **Access Legacy Admin Console:**

   No port forwarding needed - it's directly accessible:
   ```bash
   # Get VM1 IP
   cd terraform
   VM1_IP=$(terraform output -json ec2_public_ips | jq -r '.vm1')
   echo "Admin Console: http://$VM1_IP:5002"
   ```

   Open in browser: **http://<VM1_IP>:5002**

   You should see the admin dashboard showing orders and statistics.

#### Option B: Expose via LoadBalancer (Production Setup)

To expose services publicly without port forwarding:

```bash
# Change frontend service to LoadBalancer type
kubectl patch svc frontend -n datadog-demo -p '{"spec":{"type":"LoadBalancer"}}'

# Wait for LoadBalancer to be provisioned (2-3 minutes)
kubectl get svc frontend -n datadog-demo -w

# Get the LoadBalancer URL
FRONTEND_URL=$(kubectl get svc frontend -n datadog-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Frontend URL: http://$FRONTEND_URL"
```

**Note**: LoadBalancer will incur additional AWS costs (~$16/month).

---

## Testing the Application

### Test Complete E-Commerce Flow

1. **Open Frontend**: http://localhost:8080 (or LoadBalancer URL)

2. **Browse Products**: You should see a grid of products

3. **Add to Cart**: Click "Add to Cart" on any product

4. **View Cart**: Click "Cart" button in header

5. **Checkout**: Click "Proceed to Checkout"
   - This creates orders in the database
   - Processes payments through the payment service
   - You should see "Order placed successfully!"

6. **View in Admin Console**: Open http://<VM1_IP>:5002
   - You should see your orders appear
   - Statistics should update
   - Shows orders by status

### Generate Test Traffic

Create a script to generate realistic traffic:

```bash
cat > test-traffic.sh << 'EOF'
#!/bin/bash

FRONTEND_URL="http://localhost:8080"
echo "Generating test traffic to $FRONTEND_URL"
echo "Make sure port-forward is running!"
echo ""

for i in {1..20}; do
  echo "[$i/20] Simulating user session..."

  # Browse products
  curl -s "$FRONTEND_URL/api/products" > /dev/null

  # Create an order
  ORDER_DATA=$(cat <<JSON
{
  "user_id": 1,
  "product_name": "Test Product $i",
  "quantity": $((RANDOM % 5 + 1)),
  "price": $((RANDOM % 100 + 10)).99
}
JSON
)

  curl -s -X POST "$FRONTEND_URL/api/orders" \
    -H "Content-Type: application/json" \
    -d "$ORDER_DATA" > /dev/null

  # Random delay between requests
  sleep $((RANDOM % 5 + 2))
done

echo ""
echo "✓ Test traffic generation complete!"
echo "Check admin console: http://<VM1_IP>:5002"
EOF

chmod +x test-traffic.sh
./test-traffic.sh
```

---

## Project Structure

```
aws-env/
├── README.md                                  # This file
├── .gitignore                                # Git ignore rules
├── .env.example                              # Environment template
├── Makefile                                  # Automation commands
├── terraform/                                # Infrastructure as Code
│   ├── main.tf                              # Main orchestration
│   ├── variables.tf                         # Variable definitions
│   ├── outputs.tf                           # Terraform outputs
│   ├── terraform.tfvars                     # Your configuration (create this)
│   ├── versions.tf                          # Provider versions
│   ├── modules/
│   │   ├── vpc/                             # VPC networking module
│   │   ├── eks/                             # Kubernetes cluster module
│   │   ├── ec2/                             # Virtual machines module
│   │   ├── rds/                             # PostgreSQL database module
│   │   ├── elasticache/                     # Redis cache module
│   │   └── alb/                             # Load balancer module
│   └── datadog/                             # Phase 4 Datadog config
├── kubernetes/                               # K8s manifests
│   ├── base/
│   │   └── namespace.yaml                   # Namespace definition
│   └── apps/
│       ├── frontend/                        # Frontend deployment & service
│       ├── api-gateway/                     # API Gateway deployment & service
│       ├── order-service/                   # Order service deployment & service
│       └── payment-service/                 # Payment service deployment & service
├── applications/                             # Application source code
│   ├── frontend/                            # Node.js + Vanilla JS
│   │   ├── server.js                       # Express server
│   │   ├── public/                         # Static files
│   │   │   ├── index.html                 # Main HTML
│   │   │   └── app.js                     # Client-side JS
│   │   ├── Dockerfile                     # Container image
│   │   └── package.json                   # Dependencies
│   ├── api-gateway/                         # Node.js/Express gateway
│   ├── order-service/                       # Python/Flask service
│   ├── payment-service/                     # Go/Gin service
│   └── legacy-admin/                        # Legacy Flask app (EC2)
│       ├── app.py                          # Flask application
│       └── requirements.txt                # Python dependencies
├── scripts/                                  # Automation scripts
│   └── demo-scenarios/                      # Demo scenario scripts
├── datadog-configs/                         # Datadog agent configs (Phase 4)
│   ├── agent-configs/
│   ├── apm/
│   ├── integrations/
│   ├── logs/
│   └── security/
└── docs/                                     # Additional documentation
```

---

## Cost Estimation

**Monthly Cost**: ~$173 (eu-central-1, on-demand pricing)

| Component | Type | Size | Monthly Cost (On-Demand) | Cost (Reserved 1yr) |
|-----------|------|------|--------------|---------------------|
| EKS Control Plane | - | - | $73 | $73 |
| EKS Nodes | t3.small | 2x | $30 | $20 (33% savings) |
| EC2 VMs | t3.small + t3.micro | 2x | $22.50 | $15 (33% savings) |
| RDS PostgreSQL | db.t3.micro | 1x | $15 | $10 (33% savings) |
| ElastiCache Redis | cache.t3.micro | 1x | $12 | $8 (33% savings) |
| Application Load Balancer | - | 1x | $16 | $16 |
| Data Transfer | ~50GB | - | $4.50 | $4.50 |
| **Total** | | | **~$173/mo** | **~$146/mo** |

### Cost Optimization

Since this infrastructure runs continuously:

- **Recommended**: Purchase 1-year Reserved Instances (saves ~$27/month = $324/year)
- **Alternative**: Use Savings Plans for EC2/RDS (flexible, similar savings)
- **EKS Nodes**: Consider spot instances for non-critical workloads (up to 60% savings)
- **Monitoring**: Set up AWS Cost Anomaly Detection alerts
- **Right-sizing**: Review CloudWatch metrics monthly and adjust instance sizes

### Cost Management Tips

```bash
# Check current costs
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '30 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=SERVICE

# Set up billing alerts in AWS Console:
# CloudWatch > Billing > Create Alarm
```

---

## Useful Commands

### Infrastructure Management

```bash
# View all Terraform outputs
cd terraform && terraform output

# View specific output
terraform output eks_cluster_endpoint
terraform output rds_endpoint

# Update infrastructure (after modifying .tf files)
terraform plan
terraform apply

# Destroy everything (WARNING: Deletes all resources and data)
terraform destroy
```

### Kubernetes Operations

```bash
# View all resources in namespace
kubectl get all -n datadog-demo

# View pod logs
kubectl logs -n datadog-demo <pod-name>
kubectl logs -n datadog-demo -l app=frontend --tail=100

# Follow logs in real-time
kubectl logs -n datadog-demo -l app=api-gateway -f

# Execute commands in pod
kubectl exec -n datadog-demo deployment/frontend -- curl http://api-gateway/health

# Restart deployments (rolling restart)
kubectl rollout restart deployment -n datadog-demo

# Restart specific deployment
kubectl rollout restart deployment frontend -n datadog-demo

# Scale deployments
kubectl scale deployment frontend -n datadog-demo --replicas=3

# Port forward services
kubectl port-forward -n datadog-demo svc/frontend 8080:80
kubectl port-forward -n datadog-demo svc/api-gateway 3000:80

# Stop all port forwards
pkill -f "port-forward"

# Describe resources for debugging
kubectl describe pod <pod-name> -n datadog-demo
kubectl describe svc frontend -n datadog-demo

# View events (useful for troubleshooting)
kubectl get events -n datadog-demo --sort-by='.lastTimestamp'
```

### Database Operations

```bash
# Connect to PostgreSQL from local machine
cd terraform
psql -h $(terraform output -raw rds_address) -U dbadmin -d ecommerce

# Connect to Redis
redis-cli -h $(terraform output -raw redis_endpoint | cut -d: -f1) -p 6379

# Run query from command line
PGPASSWORD='YourPassword' psql -h $(terraform output -raw rds_address) -U dbadmin -d ecommerce -c "SELECT * FROM orders LIMIT 10;"

# From a Kubernetes pod
kubectl run psql-client -n datadog-demo --rm -it --image=postgres:16 --restart=Never -- \
  psql -h <rds-endpoint> -U dbadmin -d ecommerce
```

### EC2 Operations

```bash
# SSH to VM1 (legacy admin)
cd terraform
ssh -i ~/.ssh/datadog-demo-key.pem ec2-user@$(terraform output -json ec2_public_ips | jq -r '.vm1')

# Check legacy admin service status
ssh -i ~/.ssh/datadog-demo-key.pem ec2-user@<VM1_IP> 'sudo systemctl status legacy-admin'

# View legacy admin logs remotely
ssh -i ~/.ssh/datadog-demo-key.pem ec2-user@<VM1_IP> 'sudo journalctl -u legacy-admin -f'

# Restart legacy admin service
ssh -i ~/.ssh/datadog-demo-key.pem ec2-user@<VM1_IP> 'sudo systemctl restart legacy-admin'
```

### Monitoring & Debugging

```bash
# Check pod resource usage
kubectl top pods -n datadog-demo

# Check node resource usage
kubectl top nodes

# Describe a failing pod
kubectl describe pod <pod-name> -n datadog-demo | grep -A 10 Events

# Get pod logs for crashes
kubectl logs <pod-name> -n datadog-demo --previous

# Check service endpoints
kubectl get endpoints -n datadog-demo

# Test internal DNS resolution
kubectl run test-dns -n datadog-demo --rm -it --image=busybox --restart=Never -- nslookup api-gateway
```

---

## Troubleshooting

### EKS Cluster Issues

#### Nodes Not Appearing
```bash
# Check node group status
aws eks describe-nodegroup \
  --cluster-name datadog-demo-cluster \
  --nodegroup-name <nodegroup-name> \
  --query 'nodegroup.status'

# Check node group health issues
aws eks describe-nodegroup \
  --cluster-name datadog-demo-cluster \
  --nodegroup-name <nodegroup-name> \
  --query 'nodegroup.health'

# Verify IAM roles
aws iam list-attached-role-policies --role-name <node-role-name>
```

#### Cannot Connect to Cluster
```bash
# Re-configure kubectl
aws eks update-kubeconfig --name datadog-demo-cluster --region <your-region>

# Check cluster is active
aws eks describe-cluster --name datadog-demo-cluster --query 'cluster.status'

# Verify AWS credentials
aws sts get-caller-identity
```

### Kubernetes Pod Issues

#### Pods Stuck in Pending
```bash
# Check pod events
kubectl describe pod <pod-name> -n datadog-demo

# Common issues:
# 1. Insufficient resources
kubectl describe nodes  # Check Available CPU/Memory

# 2. Image pull issues
kubectl get events -n datadog-demo | grep -i pull

# 3. PVC issues (not applicable to this project)
kubectl get pvc -n datadog-demo
```

#### Pods Crashing (CrashLoopBackOff)
```bash
# View current logs
kubectl logs <pod-name> -n datadog-demo

# View previous crash logs
kubectl logs <pod-name> -n datadog-demo --previous

# Common causes:
# 1. ConfigMap/Secret not created
kubectl get configmap,secret -n datadog-demo

# 2. Database connection issues
kubectl exec -n datadog-demo <pod-name> -- env | grep DB_

# 3. Application errors - check logs above
```

#### ImagePullBackOff
```bash
# Check image name in deployment
kubectl get deployment <service-name> -n datadog-demo -o jsonpath='{.spec.template.spec.containers[0].image}'

# Check image pull secret (if private registry)
kubectl get secrets -n datadog-demo

# Manually try to pull image
docker pull <image-name>
```

### Database Connectivity Issues

#### Cannot Connect to RDS from Pods
```bash
# 1. Check RDS is running
aws rds describe-db-instances \
  --db-instance-identifier datadog-demo-postgres \
  --query 'DBInstances[0].DBInstanceStatus'

# 2. Check security group allows connections from EKS
aws ec2 describe-security-groups \
  --group-ids <rds-security-group-id> \
  --query 'SecurityGroups[0].IpPermissions'

# 3. Test from a pod
kubectl run db-test -n datadog-demo --rm -it --image=postgres:16 --restart=Never -- \
  psql -h <rds-endpoint> -U dbadmin -d ecommerce -c "SELECT 1"

# 4. Check ConfigMap has correct values
kubectl get configmap app-config -n datadog-demo -o yaml
```

#### Wrong Database Password
```bash
# Check secret exists
kubectl get secret app-secrets -n datadog-demo

# Delete and recreate with correct password
kubectl delete secret app-secrets -n datadog-demo
kubectl create secret generic app-secrets -n datadog-demo \
  --from-literal=DB_PASSWORD='YourCorrectPassword'

# Restart pods to pick up new secret
kubectl rollout restart deployment -n datadog-demo
```

### Service Communication Issues

#### Services Cannot Reach Each Other
```bash
# 1. Check services exist and have endpoints
kubectl get svc -n datadog-demo
kubectl get endpoints -n datadog-demo

# 2. Test DNS resolution
kubectl run test-dns -n datadog-demo --rm -it --image=busybox --restart=Never -- \
  nslookup api-gateway.datadog-demo.svc.cluster.local

# 3. Test connectivity between services
kubectl exec -n datadog-demo deployment/frontend -- \
  curl -v http://api-gateway/health

# 4. Check network policies (none in this project, but worth checking)
kubectl get networkpolicies -n datadog-demo
```

### EC2 / Legacy Admin Issues

#### Cannot SSH to EC2
```bash
# 1. Check instance is running
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=*app-server*" \
  --query 'Reservations[*].Instances[*].[State.Name,PublicIpAddress]'

# 2. Check security group allows SSH from your IP
aws ec2 describe-security-groups \
  --group-ids <ec2-security-group-id> \
  --query 'SecurityGroups[0].IpPermissions[?FromPort==`22`]'

# 3. Verify key permissions
ls -la ~/.ssh/datadog-demo-key.pem  # Should be -r--------

# 4. Use Systems Manager as alternative
aws ssm start-session --target <instance-id>
```

#### Legacy Admin Not Starting
```bash
# SSH to EC2 and check logs
ssh -i ~/.ssh/datadog-demo-key.pem ec2-user@<VM1_IP>

# Check service status
sudo systemctl status legacy-admin

# View full logs
sudo journalctl -u legacy-admin -n 100 --no-pager

# Check if port 5002 is listening
sudo netstat -tlnp | grep 5002

# Common issues:
# 1. Missing dependencies
pip3 list | grep -i flask

# 2. Wrong database endpoint in .env
cat ~/aws-env/applications/legacy-admin/.env

# 3. Database connection fails
psql -h <db-host> -U dbadmin -d ecommerce

# Restart service
sudo systemctl restart legacy-admin
```

#### Legacy Admin Cannot Connect to Database
```bash
# Check RDS security group allows EC2 instance
aws ec2 describe-security-groups \
  --group-ids <rds-security-group-id> \
  --query 'SecurityGroups[0].IpPermissions[?FromPort==`5432`]'

# From EC2, test connection
telnet <rds-endpoint> 5432

# Test with psql
psql -h <rds-endpoint> -U dbadmin -d ecommerce

# Check .env file has correct values
cat ~/aws-env/applications/legacy-admin/.env
```

### Port Forwarding Issues

#### Port Forward Keeps Dying
```bash
# Kill all existing port forwards
pkill -f "port-forward"

# Check if port is already in use
lsof -i :8080

# Start with verbose output to see errors
kubectl port-forward -n datadog-demo svc/frontend 8080:80 -v=9

# Common causes:
# 1. AWS credentials expired - re-run: aws sso login
# 2. Pod restarted - port forward doesn't reconnect automatically
# 3. Network connectivity issues
```

#### Cannot Access localhost:8080
```bash
# 1. Check port forward is running
ps aux | grep "port-forward.*frontend"

# 2. Check service exists
kubectl get svc frontend -n datadog-demo

# 3. Check pods are running
kubectl get pods -n datadog-demo -l app=frontend

# 4. Try forwarding to pod directly
kubectl port-forward -n datadog-demo pod/<frontend-pod-name> 8080:8080

# 5. Check application is listening on correct port
kubectl exec -n datadog-demo deployment/frontend -- netstat -tlnp | grep 8080
```

### Terraform Issues

#### State Lock Error
```bash
# If you see "Error locking state", someone else may be running terraform
# Or a previous run didn't complete properly

# Force unlock (use with caution!)
terraform force-unlock <lock-id>
```

#### Resource Already Exists
```bash
# Import existing resource into state
terraform import <resource-type>.<resource-name> <resource-id>

# Or remove from state and recreate
terraform state rm <resource-address>
terraform apply
```

#### Terraform Apply Fails Midway
```bash
# Don't panic! Terraform state tracks what was created
# Simply run again:
terraform apply

# To see what exists:
terraform show

# To see what needs to be done:
terraform plan
```

---

## Security Best Practices

### For Production Deployments

1. **Secrets Management**
   - Use AWS Secrets Manager for database passwords
   - Never commit `terraform.tfvars` with real passwords to Git
   - Rotate database passwords regularly
   - Use IAM roles for pod authentication (IRSA)

2. **Network Security**
   - Restrict `ec2_ssh_allowed_cidr` to your IP only
   - Restrict `alb_allowed_cidr` to known IPs if possible
   - Use private subnets for all application workloads
   - Enable VPC Flow Logs

3. **Database Security**
   - Enable encryption at rest for RDS
   - Enable encryption at rest for ElastiCache
   - Set `rds_multi_az = true` for production
   - Enable automated backups (already configured)
   - Restrict database access to application security groups only

4. **Kubernetes Security**
   - Use Pod Security Standards
   - Implement Network Policies to restrict pod-to-pod communication
   - Enable audit logging on EKS cluster
   - Use IRSA (IAM Roles for Service Accounts) for AWS API access
   - Regularly update EKS cluster version

5. **Monitoring & Compliance**
   - Enable AWS GuardDuty for threat detection
   - Enable AWS Config for compliance monitoring
   - Set up CloudTrail for API auditing
   - Configure AWS Security Hub

6. **Access Control**
   - Use AWS SSO for console access
   - Implement MFA for all IAM users
   - Follow principle of least privilege for IAM roles
   - Regularly review and rotate access keys

### Update `.gitignore`

Ensure these are in your `.gitignore`:
```
# Terraform
terraform.tfvars
*.tfstate
*.tfstate.backup
.terraform/

# Secrets
.env
*.pem
*.key

# Kubernetes secrets
*secret*.yaml
```

---

## Next Steps: Phase 4 - Datadog Integration

Once the infrastructure and applications are running, proceed with Datadog integration:

### 1. Install Datadog Agents

**EKS Cluster:**
```bash
# Add Datadog Helm repo
helm repo add datadog https://helm.datadoghq.com
helm repo update

# Install Datadog Agent
helm install datadog-agent datadog/datadog \
  --set datadog.apiKey=<DD_API_KEY> \
  --set datadog.site=datadoghq.com \
  --namespace datadog-demo \
  --set datadog.logs.enabled=true \
  --set datadog.apm.enabled=true
```

**EC2 Instances:**
```bash
ssh -i ~/.ssh/datadog-demo-key.pem ec2-user@<VM1_IP>
DD_API_KEY=<YOUR_API_KEY> DD_SITE="datadoghq.com" bash -c "$(curl -L https://s.datadoghq.com/scripts/install_script_agent7.sh)"
```

### 2. Enable APM (Application Performance Monitoring)

Add Datadog tracing libraries to each service:
- **Node.js**: `dd-trace`
- **Python**: `ddtrace`
- **Go**: `dd-trace-go`

### 3. Configure RUM (Real User Monitoring)

Add Datadog RUM SDK to frontend `index.html`

### 4. Set Up Logs

Configure log collection and trace correlation

### 5. Deploy Monitors & Dashboards

Use Terraform in `terraform/datadog/` to deploy:
- Service health monitors
- Custom dashboards
- Synthetic tests
- SLOs

---

## Maintenance & Updates

### Update Application Code

When you modify application code:

```bash
# Option 1: If using existing public images, just restart pods
kubectl rollout restart deployment -n datadog-demo

# Option 2: If you built new images
# 1. Build and push new images
# 2. Update Kubernetes deployments
kubectl set image deployment/frontend frontend=<new-image> -n datadog-demo
kubectl rollout status deployment/frontend -n datadog-demo
```

### Update Infrastructure

```bash
# Make changes to .tf files
nano terraform/main.tf

# Plan changes
terraform plan

# Apply changes
terraform apply
```

### Upgrade EKS Cluster

```bash
# Update cluster version in terraform.tfvars
eks_cluster_version = "1.33"

# Apply update
cd terraform
terraform plan
terraform apply

# Update node group (will cause rolling update)
```

### Backup & Disaster Recovery

```bash
# RDS automatic backups are enabled (7-day retention)
# Manual snapshot:
aws rds create-db-snapshot \
  --db-instance-identifier datadog-demo-postgres \
  --db-snapshot-identifier datadog-demo-manual-backup-$(date +%Y%m%d)

# Export Terraform state
cd terraform
terraform state pull > terraform-state-backup-$(date +%Y%m%d).json

# Backup Kubernetes resources
kubectl get all -n datadog-demo -o yaml > k8s-backup-$(date +%Y%m%d).yaml
```

---

## Decommissioning

When you're done with the demo environment and want to tear it down:

### Step 1: Backup Important Data

```bash
# Export any data you want to keep
kubectl get all -n datadog-demo -o yaml > final-k8s-backup.yaml
cd terraform
terraform output > final-outputs.txt
```

### Step 2: Delete Kubernetes Resources

```bash
kubectl delete namespace datadog-demo
```

### Step 3: Destroy Infrastructure

```bash
cd terraform
terraform destroy
```

Type `yes` when prompted. This will delete:
- EKS cluster and nodes
- EC2 instances
- RDS database (with deletion protection disabled first)
- ElastiCache cluster
- VPC and all networking
- Security groups
- IAM roles

**Warning**: This is irreversible. All data will be lost.

### Step 4: Clean Up AWS Resources Not Managed by Terraform

```bash
# Delete SSH key pair
aws ec2 delete-key-pair --key-name datadog-demo-key
rm ~/.ssh/datadog-demo-key.pem

# Check for any orphaned resources
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=datadog-demo"
aws eks list-clusters --query 'clusters[?contains(@, `datadog-demo`)]'
```

### Cost After Deletion

Once destroyed, you'll only incur costs for:
- S3 buckets (if you created any)
- CloudWatch logs retention
- Backups/snapshots if you created manual ones

---

## Support & Resources

### Documentation
- **AWS EKS**: https://docs.aws.amazon.com/eks/
- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/
- **Kubernetes**: https://kubernetes.io/docs/

### Troubleshooting
- Review this README's Troubleshooting section
- Check application logs: `kubectl logs -n datadog-demo <pod-name>`
- Check Terraform state: `terraform show`
- Check AWS CloudWatch logs

### Common Issues
- **AWS Credentials Expired**: Run `aws sso login`
- **kubectl Not Working**: Re-run `aws eks update-kubeconfig`
- **Port Forward Died**: Restart with `kubectl port-forward`
- **Pods Not Starting**: Check logs and events

---

## License

For internal Datadog sales engineering use.

---

## Summary

**You have successfully deployed:**
✅ Complete AWS infrastructure with Terraform
✅ EKS cluster with 4 microservices
✅ RDS PostgreSQL database
✅ ElastiCache Redis cluster
✅ Legacy admin application on EC2
✅ Fully functional e-commerce application

**Access Your Applications:**
- **Frontend**: http://localhost:8080 (via port-forward)
- **Admin Dashboard**: http://<VM1_IP>:5002

**Next Steps:**
- Test the e-commerce flow
- Generate traffic with test scripts
- Proceed to Phase 4: Datadog Integration

---

**Current Status**: Phase 3 Complete ✅
**Infrastructure**: Running in AWS
**Applications**: Deployed and functional
**Next Phase**: Datadog Integration (Phase 4)
