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

### Prerequisites

Before you begin, ensure you have:

1. **AWS Account** with appropriate permissions:
   - EC2, EKS, VPC, RDS, ElastiCache management
   - IAM role/user creation
   - Ability to create Load Balancers

2. **Tools Installed**:
   ```bash
   # Verify installations
   aws --version          # AWS CLI >= 2.0
   terraform --version    # Terraform >= 1.0
   kubectl version        # kubectl >= 1.27
   docker --version       # Docker >= 20.0
   ```

3. **AWS CLI Configured**:
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

4. **SSH Key Pair** (Required for EC2 Access):

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

5. **GitHub Access**: Clone this repository
   ```bash
   git clone <repository-url>
   cd aws-env
   ```

6. **Docker Images**: All images are publicly available (no authentication needed)
   - Images are hosted in a public Docker registry
   - No need to build images locally

---

## Important Notes Before You Start

⚠️ **Resource Naming**: You must use unique names in your Terraform configuration. The default names are already in use. Change these to something unique:

- **`project_name`**: Change from `datadog-demo` to `datadog-demo-yourname` (or similar)
- **`eks_cluster_name`**: Change from `datadog-demo-cluster` to `datadog-demo-yourname-cluster` (or similar)

These names are used to create AWS resources and must be unique to avoid conflicts.

---

## Step-by-Step Deployment

#### Step 1: Configure Terraform Variables

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
   # IMPORTANT: Change project_name to something unique!
   # This is used to name ALL AWS resources (EKS cluster, RDS, etc.)
   # Example: datadog-demo-yourname, datadog-demo-team1, etc.
   project_name = "datadog-demo-yourname"  # CHANGE THIS!
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
   eks_cluster_name        = "datadog-demo-yourname-cluster"  # CHANGE THIS to match your project_name!
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
   - **`project_name`**: Change to something unique (e.g., `datadog-demo-yourname`) - prevents naming conflicts
   - **`eks_cluster_name`**: Change to something unique (e.g., `datadog-demo-yourname-cluster`) - must be unique across AWS
   - `aws_region`: Your preferred AWS region
   - `availability_zones`: Must match your region (check AWS console)
   - `rds_master_password`: Use a strong, unique password
   - `ec2_key_name`: Must match the SSH key you created in Prerequisites

#### Step 2: Initialize and Deploy Infrastructure

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the infrastructure plan:
   ```bash
   terraform plan -out=tfplan
   ```

   This will show you all resources that will be created (~50+ resources).

3. Deploy the infrastructure:
   ```bash
   terraform apply tfplan
   ```

   ⏱️ **Expected time**: 15-20 minutes

   This creates:
   - VPC with public/private/database subnets
   - EKS cluster with node group
   - 2 EC2 instances
   - RDS PostgreSQL database
   - ElastiCache Redis cluster
   - Application Load Balancer
   - Security groups and IAM roles

4. Save the outputs:
   ```bash
   terraform output > ../infrastructure-outputs.txt
   ```

5. Verify infrastructure was created:
   ```bash
   # Check EKS cluster
   aws eks describe-cluster --name $(terraform output -raw eks_cluster_name) --query 'cluster.status'

   # Check EC2 instances
   aws ec2 describe-instances --filters "Name=tag:Project,Values=$(terraform output -raw project_name)" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],PublicIpAddress]' --output table
   ```

---

### Step 3: Configure kubectl for EKS

1. Update your kubeconfig to connect to the EKS cluster:
   ```bash
   aws eks update-kubeconfig --name $(terraform output -raw eks_cluster_name) --region $(terraform output -raw aws_region)
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

#### Step 4: Deploy Kubernetes Applications

1. Navigate back to project root:
   ```bash
   cd ..
   ```

2. Create the namespace and base configuration:
   ```bash
   kubectl apply -f kubernetes/base/namespace.yaml
   ```

3. Create ConfigMap with database connection info:
   ```bash
   # Get RDS endpoint from Terraform output
   DB_HOST=$(cd terraform && terraform output -raw rds_endpoint)

   # Create ConfigMap
   kubectl create configmap app-config -n datadog-demo \
     --from-literal=DB_HOST=$DB_HOST \
     --from-literal=DB_PORT=5432 \
     --from-literal=DB_NAME=ecommerce \
     --from-literal=DB_USER=dbadmin \
     --from-literal=REDIS_HOST=$(cd terraform && terraform output -raw redis_endpoint) \
     --from-literal=REDIS_PORT=6379
   ```

4. Create Secret with database password:
   ```bash
   # Use the password you set in terraform.tfvars
   kubectl create secret generic app-secrets -n datadog-demo \
     --from-literal=DB_PASSWORD='CHANGE-ME-SecurePassword123!'
   ```

5. Deploy all microservices:
   ```bash
   kubectl apply -f kubernetes/apps/
   ```

6. Wait for pods to be ready:
   ```bash
   kubectl get pods -n datadog-demo -w
   ```

   Wait until all pods show "1/1 Running" (press Ctrl+C to exit watch mode).

#### Step 5: Deploy Legacy Admin App to EC2

1. Get VM1 public IP:
   ```bash
   cd terraform
   terraform output -raw ec2_public_ips
   ```

2. SSH to VM1:
   ```bash
   # Replace with your actual IP
   ssh -i ~/.ssh/datadog-demo-key.pem ec2-user@<VM1_PUBLIC_IP>
   ```

   **Note**: If you don't have the SSH key, you'll need to access via AWS Systems Manager Session Manager or generate a new key.

3. On the EC2 instance, install dependencies:
   ```bash
   # Update system
   sudo yum update -y

   # Install Python 3 and pip
   sudo yum install -y python3 python3-pip git

   # Clone the repository (or upload the legacy-admin folder)
   git clone <repository-url>
   cd aws-env/applications/legacy-admin

   # Install Python dependencies
   pip3 install -r requirements.txt
   ```

4. Create environment file:
   ```bash
   cat > .env << EOF
   DB_HOST=<your-rds-endpoint>
   DB_PORT=5432
   DB_NAME=ecommerce
   DB_USER=dbadmin
   DB_PASSWORD=CHANGE-ME-SecurePassword123!
   EOF
   ```

5. Create systemd service:
   ```bash
   sudo cat > /etc/systemd/system/legacy-admin.service << EOF
   [Unit]
   Description=Legacy Admin Application
   After=network.target

   [Service]
   Type=simple
   User=ec2-user
   WorkingDirectory=/home/ec2-user/aws-env/applications/legacy-admin
   Environment="PATH=/usr/local/bin:/usr/bin:/bin"
   EnvironmentFile=/home/ec2-user/aws-env/applications/legacy-admin/.env
   ExecStart=/usr/bin/python3 app.py
   Restart=always

   [Install]
   WantedBy=multi-user.target
   EOF
   ```

6. Start the service:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable legacy-admin
   sudo systemctl start legacy-admin
   sudo systemctl status legacy-admin
   ```

#### Step 6: Verify Deployment

1. Check Kubernetes pods:
   ```bash
   kubectl get pods -n datadog-demo
   ```

   All should show "Running" status.

2. Check Kubernetes services:
   ```bash
   kubectl get svc -n datadog-demo
   ```

3. Test pod health:
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

4. Check EC2 legacy admin:
   ```bash
   curl http://<VM1_PUBLIC_IP>:5002/health
   ```

#### Step 7: Access the Applications

**Option A: Using Port Forwarding (Recommended for Testing)**

1. Forward frontend service:
   ```bash
   kubectl port-forward -n datadog-demo svc/frontend 8080:80
   ```

2. Access in browser:
   - **E-Commerce Frontend**: http://localhost:8080
   - **Legacy Admin Console**: http://<VM1_PUBLIC_IP>:5002

**Option B: Using LoadBalancer Service (Production)**

To expose services via LoadBalancer (not currently configured):
```bash
# Change frontend service type
kubectl patch svc frontend -n datadog-demo -p '{"spec":{"type":"LoadBalancer"}}'

# Get the LoadBalancer URL
kubectl get svc frontend -n datadog-demo
```

---

## Testing the Application

### Test E-Commerce Flow

1. Open frontend: http://localhost:8080 (or LoadBalancer URL)
2. Browse products
3. Add items to cart
4. Click "Proceed to Checkout"
5. Verify order completion

### Test Admin Console

1. Open admin console: http://<VM1_PUBLIC_IP>:5002
2. View orders in real-time
3. Check order statistics
4. Verify database connectivity

### Generate Test Traffic

Create a simple script to generate traffic:

```bash
# Save as test-traffic.sh
#!/bin/bash

FRONTEND_URL="http://localhost:8080"

echo "Generating test traffic..."

for i in {1..10}; do
  echo "Request $i"

  # Browse products
  curl -s "$FRONTEND_URL/api/products" > /dev/null

  # Create order
  curl -s -X POST "$FRONTEND_URL/api/orders" \
    -H "Content-Type: application/json" \
    -d '{
      "user_id": 1,
      "product_name": "Test Product",
      "quantity": 1,
      "price": 29.99
    }' > /dev/null

  sleep 2
done

echo "Traffic generation complete!"
```

Run it:
```bash
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
│   │   ├── namespace.yaml                   # Namespace: datadog-demo
│   │   ├── configmap.yaml                   # App configuration
│   │   └── secret.yaml                      # Database secrets
│   └── apps/
│       ├── frontend/                        # Frontend deployment
│       ├── api-gateway/                     # API Gateway deployment
│       ├── order-service/                   # Order service deployment
│       └── payment-service/                 # Payment service deployment
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

---

## Useful Commands

### Infrastructure Management

```bash
# View all outputs
cd terraform && terraform output

# Check infrastructure status
terraform show

# Update infrastructure (after modifying .tf files)
terraform plan
terraform apply

# Destroy everything (WARNING: Deletes all resources)
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
kubectl exec -n datadog-demo deployment/frontend -- <command>

# Restart deployments
kubectl rollout restart deployment -n datadog-demo

# Scale deployments
kubectl scale deployment frontend -n datadog-demo --replicas=3

# Port forward services
kubectl port-forward -n datadog-demo svc/frontend 8080:80
kubectl port-forward -n datadog-demo svc/api-gateway 3000:80

# Describe resources for debugging
kubectl describe pod <pod-name> -n datadog-demo
kubectl describe svc frontend -n datadog-demo
```

### Database Operations

```bash
# Connect to PostgreSQL
psql -h <rds-endpoint> -U dbadmin -d ecommerce

# Connect to Redis
redis-cli -h <redis-endpoint> -p 6379

# From a pod
kubectl run psql-client -n datadog-demo --rm -it --image=postgres:16 -- bash
psql -h <rds-endpoint> -U dbadmin -d ecommerce
```

### EC2 Operations

```bash
# SSH to VM1 (legacy admin)
ssh -i ~/.ssh/datadog-demo-key.pem ec2-user@<VM1_PUBLIC_IP>

# Check legacy admin service status
sudo systemctl status legacy-admin

# View legacy admin logs
sudo journalctl -u legacy-admin -f

# Restart legacy admin
sudo systemctl restart legacy-admin
```

---

## Troubleshooting

### EKS Nodes Not Appearing

```bash
# Check node status
kubectl get nodes

# If no nodes, check EKS console or:
aws eks describe-nodegroup --cluster-name datadog-demo-cluster --nodegroup-name <nodegroup-name>

# Verify IAM roles
aws iam list-attached-role-policies --role-name <node-role-name>
```

### Pods Stuck in Pending

```bash
# Check pod events
kubectl describe pod <pod-name> -n datadog-demo

# Check node capacity
kubectl describe nodes

# Check if images are pulling
kubectl get events -n datadog-demo --sort-by='.lastTimestamp'
```

### Cannot Connect to RDS

```bash
# Verify security group allows connections
aws ec2 describe-security-groups --group-ids <rds-sg-id>

# Test from a pod
kubectl run test-db -n datadog-demo --rm -it --image=postgres:16 -- bash
psql -h <rds-endpoint> -U dbadmin -d ecommerce
```

### Services Not Responding

```bash
# Check pod logs for errors
kubectl logs -n datadog-demo -l app=<service-name> --tail=50

# Check service endpoints
kubectl get endpoints -n datadog-demo

# Test internal connectivity
kubectl run test-pod -n datadog-demo --rm -it --image=curlimages/curl -- sh
curl http://api-gateway/health
```

### Port Forward Not Working

```bash
# Kill existing port forwards
pkill -f "port-forward"

# Verify pod is running
kubectl get pods -n datadog-demo

# Try forwarding to pod directly
kubectl port-forward -n datadog-demo pod/<pod-name> 8080:8080
```

---

## Security Notes

- All secrets should be stored in AWS Secrets Manager or Kubernetes Secrets
- Never commit `.env` files or `terraform.tfvars` to git
- Use IAM roles for pod authentication (IRSA) in production
- Enable encryption at rest for RDS and ElastiCache
- Use HTTPS/TLS for all external traffic
- Rotate database passwords regularly
- Enable AWS GuardDuty for threat detection
- Review security groups and network ACLs regularly

---

## Next Steps: Phase 4 - Datadog Integration

Once the infrastructure and applications are running, you can proceed with Datadog integration:

1. **Install Datadog Agents**
   - Deploy Datadog agent to EKS cluster
   - Install agent on EC2 instances

2. **Enable APM**
   - Add Datadog tracing libraries to all services
   - Configure trace collection and sampling

3. **Configure RUM**
   - Add RUM SDK to frontend application
   - Enable session replay

4. **Set Up Logs**
   - Configure log collection from all services
   - Enable trace-log correlation

5. **Deploy Monitors & Dashboards**
   - Create service-level monitors
   - Build custom dashboards
   - Set up alerting

(Detailed Phase 4 instructions coming soon)

---

## Support

For issues or questions:
- Review this README carefully
- Check the Troubleshooting section
- Verify all prerequisites are met
- Review Terraform and Kubernetes logs
- Check AWS CloudWatch logs

---

## License

For internal Datadog sales engineering use.

---

**Current Status**: Phase 3 Complete ✅
**Infrastructure**: Running in AWS
**Applications**: Deployed and functional
**Next Phase**: Datadog Integration (Phase 4)
