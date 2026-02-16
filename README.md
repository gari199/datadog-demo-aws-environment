# AWS Datadog Demo Environment

A comprehensive AWS environment designed to showcase all Datadog capabilities for sales demonstrations and testing.

## Overview

This project creates a production-like AWS environment with:
- **2 EC2 VMs**: Legacy application server + Utility server
- **1 EKS Cluster**: Small Kubernetes cluster with 4 microservices
- **Supporting Services**: RDS PostgreSQL, ElastiCache Redis, Application Load Balancer

## Architecture

```
Internet → Application Load Balancer
    ├── EC2 VM 1: Legacy Python/Flask Admin App → RDS PostgreSQL
    ├── EC2 VM 2: Utility Server (background jobs, security monitoring)
    └── EKS Cluster (2 t3.small nodes):
        ├── Frontend Pod (React + Node.js) - RUM, Session Replay
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
- **Container Orchestration**: Amazon EKS (Kubernetes)
- **Languages**: Python, Node.js, Go, React
- **Database**: PostgreSQL (RDS)
- **Cache**: Redis (ElastiCache)
- **Load Balancer**: AWS Application Load Balancer

## Implementation Phases

This project is implemented in 4 phases for easier debugging:

| Phase | Focus | Duration | Status |
|-------|-------|----------|--------|
| **Phase 1** | Folder Structure | 30 min | ✅ Complete |
| **Phase 2** | Infrastructure | 2-3 hrs | 🔄 Next |
| **Phase 3** | Applications | 4-6 hrs | ⏳ Pending |
| **Phase 4** | Datadog | 3-4 hrs | ⏳ Pending |

### Phase 1: Folder Structure ✅
- Complete project skeleton created
- Git repository initialized
- Configuration examples provided

### Phase 2: Terraform Infrastructure (Next)
- Deploy AWS resources (VPC, EKS, EC2, RDS, ElastiCache, ALB)
- Verify all infrastructure components
- No applications deployed yet

### Phase 3: Application Microservices
- Build and deploy 4 microservices to Kubernetes
- Deploy legacy admin app to EC2
- Test end-to-end without Datadog instrumentation

### Phase 4: Datadog Integration
- Install Datadog agents on all infrastructure
- Add APM instrumentation to all services
- Enable RUM, logs, security monitoring
- Create monitors, dashboards, and synthetic tests

## Quick Start

### Prerequisites

- AWS CLI configured with credentials
- Terraform >= 1.0
- kubectl >= 1.27
- Docker
- Helm
- Datadog account (for Phase 4)

### Phase 2: Deploy Infrastructure

```bash
# 1. Configure variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your AWS settings

# 2. Deploy infrastructure
cd terraform
terraform init
terraform plan
terraform apply

# 3. Configure kubectl
aws eks update-kubeconfig --name datadog-demo-cluster --region eu-central-1

# 4. Verify
kubectl get nodes
```

### Phase 3: Deploy Applications (After Phase 2)

```bash
# Build and deploy microservices
./scripts/build-images.sh
./scripts/deploy-apps.sh

# Test end-to-end
curl https://<alb-endpoint>/api/health
```

### Phase 4: Add Datadog Monitoring (After Phase 3)

```bash
# Set Datadog credentials
export DD_API_KEY="your-api-key"
export DD_APP_KEY="your-app-key"
export DD_RUM_APPLICATION_ID="your-rum-app-id"
export DD_RUM_CLIENT_TOKEN="your-rum-client-token"

# Install Datadog agents
./scripts/install-datadog-agents.sh

# Rebuild apps with Datadog instrumentation
./scripts/rebuild-with-datadog.sh

# Deploy Datadog configuration
cd terraform/datadog
terraform init
terraform apply
```

## Project Structure

```
aws-env/
├── terraform/              # Infrastructure as Code
│   ├── modules/           # Terraform modules (VPC, EKS, EC2, RDS, etc.)
│   └── datadog/           # Datadog monitors, dashboards, synthetics
├── kubernetes/            # Kubernetes manifests
│   ├── base/             # Namespace, ConfigMaps
│   └── apps/             # Application deployments
├── applications/          # Application source code
│   ├── frontend/         # React + Node.js
│   ├── api-gateway/      # Node.js/Express
│   ├── order-service/    # Python/Flask
│   ├── payment-service/  # Go/Gin
│   └── legacy-admin/     # Python/Flask (EC2)
├── scripts/              # Automation scripts
├── datadog-configs/      # Datadog agent configurations
└── docs/                 # Documentation
```

## Cost Estimation

**Monthly Cost**: ~$173 (eu-central-1, on-demand pricing) for always-on infrastructure

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

### Cost Optimization for Always-On Infrastructure

Since this infrastructure runs continuously:

- **Recommended**: Purchase 1-year Reserved Instances (saves ~$27/month, $324/year)
- **Alternative**: Use Savings Plans for EC2/RDS (flexible, similar savings)
- **EKS Nodes**: Consider spot instances for non-critical workloads (up to 60% savings)
- **Monitoring**: Set up AWS Cost Anomaly Detection alerts
- **Right-sizing**: Review CloudWatch metrics monthly and adjust instance sizes
- **Storage**: Enable RDS automated backups with retention policies

## Demo Scenarios

### Scenario 1: APM & Distributed Tracing
```bash
./scripts/demo-scenarios/scenario-1-apm-trace.sh
```
Shows distributed tracing across all 4 microservices with database queries.

### Scenario 2: RUM & Session Replay
```bash
./scripts/demo-scenarios/scenario-2-rum-session.sh
```
Demonstrates real user monitoring and session replay features.

### Scenario 3: Security Monitoring
```bash
./scripts/demo-scenarios/scenario-3-security-alert.sh
```
Triggers security events (SQL injection, file access violations).

### Scenario 4: Database Monitoring
```bash
./scripts/demo-scenarios/scenario-4-dbm.sh
```
Shows database query performance and optimization opportunities.

## Useful Commands

```bash
# Generate demo traffic
./scripts/generate-traffic.sh

# View logs from a service
kubectl logs -n datadog-demo -l app=api-gateway

# Check infrastructure status
make status

# View all endpoints and IPs
make outputs

# SSH to EC2 instance
ssh ec2-user@<ec2-public-ip>

# Update kubectl config
aws eks update-kubeconfig --name datadog-demo-cluster --region eu-central-1

# Deploy code updates (without recreating infrastructure)
make build-images
make deploy-k8s

# Destroy all resources (only if decommissioning environment)
make destroy
```

## Documentation

- [Deployment Guide](docs/deployment-guide.md) - Step-by-step deployment instructions
- [Demo Guide](docs/demo-guide.md) - How to run effective demos
- [Troubleshooting](docs/troubleshooting.md) - Common issues and solutions

## Environment Variables

Create a `.env` file with:

```bash
# AWS
AWS_REGION=eu-central-1
AWS_ACCOUNT_ID=your-account-id

# Datadog (Phase 4)
DD_API_KEY=your-datadog-api-key
DD_APP_KEY=your-datadog-app-key
DD_SITE=datadoghq.com
DD_RUM_APPLICATION_ID=your-rum-app-id
DD_RUM_CLIENT_TOKEN=your-rum-client-token

# Database
DB_PASSWORD=secure-random-password
REDIS_PASSWORD=secure-random-password
```

## Troubleshooting

### EKS nodes not appearing
- Check IAM roles attached to node group
- Verify security groups allow communication

### Cannot connect to RDS
- Check security groups allow traffic from EKS/EC2
- Verify database subnet group configuration

### Pods stuck in Pending
- Check node capacity: `kubectl describe nodes`
- Verify EKS node group is running

### Datadog agent not reporting (Phase 4)
- Verify DD_API_KEY is correct
- Check agent logs: `kubectl logs -n datadog-demo -l app=datadog-agent`

## Security Notes

- All secrets should be stored in AWS Secrets Manager or similar
- Never commit `.env` files or `terraform.tfvars` to git
- Use IAM roles for pod authentication (IRSA)
- Enable encryption at rest for RDS and ElastiCache
- Use HTTPS/TLS for all external traffic

## Best Practices for Always-On Infrastructure

This environment is designed to run continuously. Recommended enhancements:

1. **Backups**: Enable automated RDS backups (already configured for 7-day retention)
2. **High Availability**: Consider multi-AZ for RDS/ElastiCache for production demos
3. **Secret Management**: Use AWS Secrets Manager for database passwords
4. **Monitoring**:
   - Set up CloudWatch alarms for resource utilization
   - Configure Datadog monitors for application health
   - Enable AWS Cost Anomaly Detection
5. **Auto-scaling**: Configure HPA (Horizontal Pod Autoscaler) for Kubernetes workloads
6. **Security**:
   - Enable AWS GuardDuty for threat detection
   - Regular security patching of EC2 instances
   - Review Datadog Security signals weekly
7. **Cost Optimization**:
   - Purchase Reserved Instances after confirming usage patterns
   - Review CloudWatch metrics monthly for right-sizing opportunities

## License

For internal Datadog sales engineering use.

## Support

For issues or questions:
- Check the [Troubleshooting Guide](docs/troubleshooting.md)
- Review Terraform/Kubernetes logs
- Contact the maintainer

---

**Current Phase**: Phase 1 Complete ✅
**Next Step**: Implement Phase 2 (Terraform Infrastructure)
