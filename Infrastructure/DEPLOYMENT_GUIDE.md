# EKS Infrastructure Deployment Guide

Step-by-step guide to deploy the Banking Application infrastructure on AWS EKS.

## 📋 Prerequisites

### 1. Install Required Tools

```bash
# Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform version

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

# helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

### 2. Configure AWS Credentials

```bash
# Option 1: Using AWS CLI
aws configure
# Enter:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (e.g., us-east-1)
# - Default output format (json)

# Option 2: Using Environment Variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Verify credentials
aws sts get-caller-identity
```

### 3. Clone Repository

```bash
git clone <repository-url>
cd banking-app/infrastructure
```

## 🚀 Deployment Steps

### Step 1: Setup Terraform Backend

The backend stores Terraform state in S3 with DynamoDB for locking.

```bash
cd infrastructure/scripts
chmod +x *.sh

# Setup backend for each environment
./setup-backend.sh dev us-east-1
./setup-backend.sh staging us-east-1
./setup-backend.sh prod us-east-1
```

**Verify backend creation:**

```bash
# Check S3 bucket
aws s3 ls | grep banking-app-terraform-state

# Check DynamoDB table
aws dynamodb list-tables | grep terraform-state-lock
```

### Step 2: Review Configuration

#### Development Environment

```bash
cd infrastructure/environments/dev
cat terraform.tfvars
```

Review and modify if needed:
- VPC CIDR ranges
- Instance types
- Node counts
- RDS configuration

#### Set Database Password

**Option 1: Environment Variable (Recommended)**

```bash
export TF_VAR_db_password="$(openssl rand -base64 32)"
echo $TF_VAR_db_password  # Save this password!
```

**Option 2: AWS Secrets Manager**

```bash
# Create secret
aws secretsmanager create-secret \
  --name banking-app-db-password-dev \
  --secret-string "$(openssl rand -base64 32)"

# Update variables.tf to use data source
```

### Step 3: Initialize Terraform

```bash
cd infrastructure/environments/dev

# Initialize Terraform
terraform init

# Verify initialization
ls -la .terraform/
```

Expected output:
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

### Step 4: Validate Configuration

```bash
# Validate syntax
terraform validate

# Format code
terraform fmt -recursive

# Check for security issues (optional)
# Install tfsec: brew install tfsec
tfsec .
```

### Step 5: Plan Deployment

```bash
# Create execution plan
terraform plan -out=tfplan

# Review the plan carefully
# Check:
# - Resources to be created
# - Estimated costs
# - Security configurations
```

**Expected resources:**
- VPC with subnets
- NAT Gateways
- EKS Cluster
- Node Groups
- RDS Instance
- Security Groups
- IAM Roles
- KMS Keys
- CloudWatch Log Groups

### Step 6: Deploy Infrastructure

```bash
# Apply the plan
terraform apply tfplan

# This will take 15-20 minutes
# - VPC: ~2 minutes
# - EKS Cluster: ~10 minutes
# - Node Groups: ~5 minutes
# - RDS: ~10 minutes
```

**Monitor progress:**

```bash
# In another terminal, watch AWS resources
watch -n 5 'aws eks describe-cluster --name banking-app-dev-eks --query cluster.status'
```

### Step 7: Verify Deployment

```bash
# Get outputs
terraform output

# Important outputs:
# - cluster_name
# - cluster_endpoint
# - db_instance_endpoint
# - configure_kubectl
```

### Step 8: Configure kubectl

```bash
# Get the command from output
terraform output -raw configure_kubectl

# Or run directly
aws eks update-kubeconfig --region us-east-1 --name banking-app-dev-eks

# Verify connection
kubectl get nodes
kubectl get pods --all-namespaces
```

Expected output:
```
NAME                                        STATUS   ROLES    AGE   VERSION
ip-10-0-11-xxx.ec2.internal                 Ready    <none>   5m    v1.28.x
ip-10-0-12-xxx.ec2.internal                 Ready    <none>   5m    v1.28.x
```

### Step 9: Install Kubernetes Add-ons

#### AWS Load Balancer Controller

```bash
# Create IAM OIDC provider (if not already done by Terraform)
eksctl utils associate-iam-oidc-provider \
  --cluster banking-app-dev-eks \
  --region us-east-1 \
  --approve

# Install AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=banking-app-dev-eks \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$(terraform output -raw aws_load_balancer_controller_role_arn)

# Verify installation
kubectl get deployment -n kube-system aws-load-balancer-controller
```

#### EBS CSI Driver

```bash
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update

helm install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
  -n kube-system \
  --set controller.serviceAccount.create=true \
  --set controller.serviceAccount.name=ebs-csi-controller-sa \
  --set controller.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$(terraform output -raw ebs_csi_driver_role_arn)

# Verify installation
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
```

#### Cluster Autoscaler

```bash
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update

helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  -n kube-system \
  --set autoDiscovery.clusterName=banking-app-dev-eks \
  --set awsRegion=us-east-1 \
  --set rbac.serviceAccount.create=true \
  --set rbac.serviceAccount.name=cluster-autoscaler \
  --set rbac.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$(terraform output -raw cluster_autoscaler_role_arn)

# Verify installation
kubectl get deployment -n kube-system cluster-autoscaler
```

#### Metrics Server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify installation
kubectl get deployment metrics-server -n kube-system

# Test
kubectl top nodes
```

### Step 10: Get Database Credentials

```bash
# Get secret ARN
DB_SECRET_ARN=$(terraform output -raw db_secret_arn)

# Retrieve credentials
aws secretsmanager get-secret-value \
  --secret-id $DB_SECRET_ARN \
  --query SecretString \
  --output text | jq .

# Save output:
# {
#   "username": "dbadmin",
#   "password": "generated-password",
#   "engine": "mysql",
#   "host": "banking-app-dev-eks-db.xxxxx.us-east-1.rds.amazonaws.com",
#   "port": 3306,
#   "dbname": "banking_db"
# }
```

### Step 11: Create Kubernetes Secret for Database

```bash
# Extract values
DB_HOST=$(aws secretsmanager get-secret-value --secret-id $DB_SECRET_ARN --query SecretString --output text | jq -r .host)
DB_USER=$(aws secretsmanager get-secret-value --secret-id $DB_SECRET_ARN --query SecretString --output text | jq -r .username)
DB_PASS=$(aws secretsmanager get-secret-value --secret-id $DB_SECRET_ARN --query SecretString --output text | jq -r .password)
DB_NAME=$(aws secretsmanager get-secret-value --secret-id $DB_SECRET_ARN --query SecretString --output text | jq -r .dbname)

# Create Kubernetes secret
kubectl create secret generic banking-secrets \
  --from-literal=DB_HOST=$DB_HOST \
  --from-literal=DB_PORT=3306 \
  --from-literal=DB_NAME=$DB_NAME \
  --from-literal=DB_USERNAME=$DB_USER \
  --from-literal=DB_PASSWORD=$DB_PASS \
  --from-literal=JWT_SECRET=$(openssl rand -base64 64) \
  --namespace=banking-app

# Verify secret
kubectl get secret banking-secrets -n banking-app
```

### Step 12: Test Database Connection

```bash
# Run MySQL client pod
kubectl run mysql-client --rm -it --image=mysql:8.0 --restart=Never -- bash

# Inside the pod
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME

# Test connection
SHOW DATABASES;
USE banking_db;
SHOW TABLES;
exit
```

## 📊 Post-Deployment Verification

### Check EKS Cluster

```bash
# Cluster info
kubectl cluster-info

# Node status
kubectl get nodes -o wide

# System pods
kubectl get pods -n kube-system

# Namespaces
kubectl get namespaces
```

### Check RDS Instance

```bash
# RDS status
aws rds describe-db-instances \
  --db-instance-identifier banking-app-dev-eks-db \
  --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address,Engine,EngineVersion]' \
  --output table

# Check backups
aws rds describe-db-snapshots \
  --db-instance-identifier banking-app-dev-eks-db
```

### Check Security Groups

```bash
# List security groups
aws ec2 describe-security-groups \
  --filters "Name=tag:Project,Values=banking-app" \
  --query 'SecurityGroups[*].[GroupId,GroupName,Description]' \
  --output table
```

### Check CloudWatch Logs

```bash
# List log groups
aws logs describe-log-groups \
  --log-group-name-prefix /aws/eks/banking-app-dev

# View recent logs
aws logs tail /aws/eks/banking-app-dev-eks/cluster --follow
```

## 🔄 Deploy to Staging/Production

### Staging Deployment

```bash
cd infrastructure/environments/staging

# Set password
export TF_VAR_db_password="$(openssl rand -base64 32)"

# Initialize
terraform init

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name banking-app-staging-eks
```

### Production Deployment

```bash
cd infrastructure/environments/prod

# Set password (use a secure method)
export TF_VAR_db_password="your-secure-production-password"

# Initialize
terraform init

# Plan (review carefully!)
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name banking-app-prod-eks
```

## 🐛 Troubleshooting

### Issue: Terraform Init Fails

```bash
# Error: Backend configuration changed
terraform init -reconfigure

# Error: Provider plugin not found
terraform init -upgrade
```

### Issue: EKS Cluster Creation Fails

```bash
# Check CloudFormation stacks
aws cloudformation describe-stacks \
  --query 'Stacks[?contains(StackName, `eksctl`)].{Name:StackName,Status:StackStatus}'

# Check IAM permissions
aws iam get-user
aws iam list-attached-user-policies --user-name your-username
```

### Issue: Cannot Connect to Cluster

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name banking-app-dev-eks

# Check AWS credentials
aws sts get-caller-identity

# Verify cluster exists
aws eks describe-cluster --name banking-app-dev-eks

# Check aws-auth ConfigMap
kubectl get configmap aws-auth -n kube-system -o yaml
```

### Issue: Nodes Not Joining Cluster

```bash
# Check node group status
aws eks describe-nodegroup \
  --cluster-name banking-app-dev-eks \
  --nodegroup-name banking-app-dev-eks-node-group

# Check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups \
  --query 'AutoScalingGroups[?contains(Tags[?Key==`eks:cluster-name`].Value, `banking-app-dev-eks`)]'

# Check EC2 instances
aws ec2 describe-instances \
  --filters "Name=tag:eks:cluster-name,Values=banking-app-dev-eks" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress]'
```

### Issue: RDS Connection Timeout

```bash
# Check security groups
aws ec2 describe-security-groups --group-ids <rds-sg-id>

# Check RDS endpoint
aws rds describe-db-instances \
  --db-instance-identifier banking-app-dev-eks-db \
  --query 'DBInstances[0].Endpoint'

# Test from EKS node
kubectl run mysql-client --rm -it --image=mysql:8.0 --restart=Never -- bash
mysql -h <rds-endpoint> -u dbadmin -p
```

## 🔐 Security Checklist

- [ ] Database password is strong and stored securely
- [ ] AWS credentials are not hardcoded
- [ ] Terraform state is encrypted in S3
- [ ] VPC Flow Logs are enabled
- [ ] EKS cluster logs are enabled
- [ ] RDS encryption is enabled
- [ ] Security groups follow least privilege
- [ ] IAM roles use least privilege
- [ ] Multi-AZ is enabled for production
- [ ] Backups are configured
- [ ] CloudWatch alarms are set up

## 📈 Monitoring Setup

### CloudWatch Dashboard

```bash
# View dashboard
aws cloudwatch get-dashboard \
  --dashboard-name banking-app-dev-eks-dashboard

# Open in browser
echo "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=banking-app-dev-eks-dashboard"
```

### Set Up Alarms

```bash
# Create SNS topic for alerts
aws sns create-topic --name banking-app-dev-alerts

# Subscribe email
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:banking-app-dev-alerts \
  --protocol email \
  --notification-endpoint your-email@example.com
```

## 🎯 Next Steps

1. **Deploy Application**: Deploy your banking application to the cluster
2. **Configure Ingress**: Set up Ingress for external access
3. **Setup CI/CD**: Configure GitHub Actions or Jenkins
4. **Enable Monitoring**: Install Prometheus and Grafana
5. **Configure Backup**: Set up Velero for cluster backups
6. **Security Scanning**: Implement Falco or similar tools
7. **Cost Optimization**: Review and optimize resource usage

## 📚 Additional Resources

- [Terraform AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Kubernetes Production Best Practices](https://learnk8s.io/production-best-practices)

---

**Deployment Complete! 🎉**

Your EKS infrastructure is now ready for the Banking Application.



