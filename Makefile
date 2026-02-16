.PHONY: help setup validate clean destroy

# Default target
help:
	@echo "==================================================="
	@echo "AWS Datadog Demo Environment - Makefile Commands"
	@echo "==================================================="
	@echo ""
	@echo "Phase 1 - Project Setup:"
	@echo "  make setup              - Install required tools (terraform, kubectl, etc.)"
	@echo ""
	@echo "Phase 2 - Infrastructure:"
	@echo "  make init-terraform     - Initialize Terraform"
	@echo "  make plan-infra         - Plan infrastructure changes"
	@echo "  make deploy-infra       - Deploy AWS infrastructure"
	@echo "  make verify-infra       - Verify infrastructure deployment"
	@echo ""
	@echo "Phase 3 - Applications:"
	@echo "  make build-images       - Build Docker images for all services"
	@echo "  make push-images        - Push images to registry (ECR)"
	@echo "  make deploy-k8s         - Deploy applications to Kubernetes"
	@echo "  make deploy-ec2         - Deploy legacy app to EC2"
	@echo "  make test-apps          - Test end-to-end application flow"
	@echo ""
	@echo "Phase 4 - Datadog:"
	@echo "  make install-dd-agents  - Install Datadog agents"
	@echo "  make rebuild-with-dd    - Rebuild apps with Datadog instrumentation"
	@echo "  make deploy-dd-config   - Deploy Datadog monitors/dashboards"
	@echo ""
	@echo "Utility Commands:"
	@echo "  make validate           - Validate all configurations"
	@echo "  make generate-traffic   - Generate demo traffic"
	@echo "  make logs SERVICE=name  - View logs for a service"
	@echo "  make status             - Show infrastructure status"
	@echo "  make outputs            - Show endpoints and connection info"
	@echo "  make clean              - Clean temporary files"
	@echo ""
	@echo "Maintenance:"
	@echo "  make update-apps        - Update application code without recreating infra"
	@echo "  make destroy            - Destroy all resources (decommissioning only)"
	@echo ""
	@echo "Demo Scenarios:"
	@echo "  make demo-apm           - Run APM demo scenario"
	@echo "  make demo-rum           - Run RUM demo scenario"
	@echo "  make demo-security      - Run security demo scenario"
	@echo "  make demo-dbm           - Run database monitoring demo"
	@echo ""
	@echo "==================================================="

# Phase 1: Setup
setup:
	@echo "Installing required tools..."
	@./scripts/setup.sh

# Phase 2: Infrastructure
init-terraform:
	@echo "Initializing Terraform..."
	@cd terraform && terraform init

plan-infra:
	@echo "Planning infrastructure changes..."
	@cd terraform && terraform plan -out=tfplan

deploy-infra:
	@echo "Deploying AWS infrastructure..."
	@./scripts/deploy-infrastructure.sh

verify-infra:
	@echo "Verifying infrastructure..."
	@echo "Checking VPC..."
	@aws ec2 describe-vpcs --filters "Name=tag:Name,Values=datadog-demo-vpc" --query 'Vpcs[0].VpcId' --output text
	@echo "Checking EKS cluster..."
	@kubectl get nodes
	@echo "Checking EC2 instances..."
	@aws ec2 describe-instances --filters "Name=tag:Project,Values=datadog-demo" --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table

# Phase 3: Applications
build-images:
	@echo "Building Docker images..."
	@./scripts/build-images.sh

push-images:
	@echo "Pushing images to registry..."
	@./scripts/push-images.sh

deploy-k8s:
	@echo "Deploying applications to Kubernetes..."
	@kubectl apply -f kubernetes/base/
	@kubectl apply -f kubernetes/apps/

deploy-ec2:
	@echo "Deploying legacy app to EC2..."
	@cd applications/legacy-admin && ./deploy.sh

deploy-apps: build-images push-images deploy-k8s deploy-ec2

test-apps:
	@echo "Testing application flow..."
	@./scripts/test-flow.sh

# Phase 4: Datadog
install-dd-agents:
	@echo "Installing Datadog agents..."
	@./scripts/install-datadog-agents.sh

rebuild-with-dd:
	@echo "Rebuilding applications with Datadog instrumentation..."
	@./scripts/rebuild-with-datadog.sh

deploy-dd-config:
	@echo "Deploying Datadog configuration..."
	@cd terraform/datadog && terraform init && terraform apply

configure-datadog: install-dd-agents rebuild-with-dd deploy-dd-config

# Utility Commands
validate:
	@echo "Validating configurations..."
	@cd terraform && terraform validate
	@kubectl apply --dry-run=client -f kubernetes/

generate-traffic:
	@echo "Generating demo traffic..."
	@./scripts/generate-traffic.sh

logs:
	@ifndef SERVICE
		@echo "Error: Please specify SERVICE. Example: make logs SERVICE=api-gateway"
	@else
		@kubectl logs -n datadog-demo -l app=$(SERVICE) --tail=100 -f
	@endif

clean:
	@echo "Cleaning temporary files..."
	@find . -type f -name "*.tfplan" -delete
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "node_modules" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.log" -delete

destroy:
	@echo "This will destroy all AWS resources (for decommissioning only)."
	@echo "Note: This infrastructure is designed to run continuously."
	@read -p "Are you sure you want to destroy everything? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		./scripts/teardown.sh; \
	else \
		echo "Destroy cancelled."; \
	fi

# Update applications without recreating infrastructure
update-apps: build-images push-images
	@echo "Updating applications..."
	@kubectl rollout restart deployment -n datadog-demo
	@echo "Waiting for rollout to complete..."
	@kubectl rollout status deployment -n datadog-demo --timeout=5m

# Demo Scenarios
demo-apm:
	@echo "Running APM demo scenario..."
	@./scripts/demo-scenarios/scenario-1-apm-trace.sh

demo-rum:
	@echo "Running RUM demo scenario..."
	@./scripts/demo-scenarios/scenario-2-rum-session.sh

demo-security:
	@echo "Running security demo scenario..."
	@./scripts/demo-scenarios/scenario-3-security-alert.sh

demo-dbm:
	@echo "Running database monitoring demo..."
	@./scripts/demo-scenarios/scenario-4-dbm.sh

# Full deployment (all phases) - Only needed for initial setup
deploy-all: deploy-infra deploy-apps configure-datadog
	@echo "Full deployment complete!"
	@echo ""
	@echo "Infrastructure is now running continuously."
	@echo "Use 'make update-apps' to deploy application changes."
	@echo "Use 'make status' to check health."

# Health check
health:
	@echo "=== Health Check ==="
	@echo "Checking Kubernetes pods..."
	@kubectl get pods -n datadog-demo
	@echo ""
	@echo "Checking EC2 instances..."
	@aws ec2 describe-instances --filters "Name=tag:Project,Values=datadog-demo" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],State.Name]' --output table
	@echo ""
	@echo "Checking RDS..."
	@aws rds describe-db-instances --db-instance-identifier datadog-demo-postgres --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address]' --output table
	@echo ""
	@echo "Checking ALB..."
	@aws elbv2 describe-load-balancers --names datadog-demo-alb --query 'LoadBalancers[0].[State.Code,DNSName]' --output table 2>/dev/null || echo "ALB not found"

# Quick status check
status:
	@echo "=== Infrastructure Status ==="
	@echo "Terraform state:"
	@cd terraform && terraform show -json 2>/dev/null | jq -r '.values.root_module.resources[] | select(.type | contains("aws_")) | "\(.type): \(.values.id // .values.arn // "N/A")"' || echo "No resources deployed"
	@echo ""
	@echo "=== Kubernetes Status ==="
	@kubectl get pods -n datadog-demo 2>/dev/null || echo "No Kubernetes resources deployed"
	@echo ""
	@echo "=== EC2 Instances ==="
	@aws ec2 describe-instances --filters "Name=tag:Project,Values=datadog-demo" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],InstanceId,State.Name,PublicIpAddress]' --output table 2>/dev/null || echo "No EC2 instances found"

# Output important endpoints
outputs:
	@echo "=== Important Endpoints ==="
	@cd terraform && terraform output 2>/dev/null || echo "Run 'make deploy-infra' first"
