# Banking Application - EKS Infrastructure

Production-grade Terraform configuration for deploying a secure EKS cluster with external RDS database on AWS.

## 📁 Project Structure

```
infrastructure/
├── main.tf                      # Root module configuration
├── variables.tf                 # Root module variables
├── outputs.tf                   # Root module outputs
├── versions.tf                  # Provider versions
│
├── modules/                     # Reusable modules
│   ├── vpc/                     # VPC with public/private/database subnets
│   ├── eks/                     # EKS cluster with node groups
│   ├── rds/                     # RDS MySQL database
│   ├── security/                # Security groups
│   └── monitoring/              # CloudWatch monitoring
│
├── environments/                # Environment-specific configurations
│   ├── dev/                     # Development environment
│   ├── staging/                 # Staging environment
│   └── prod/                    # Production environment
│
└── scripts/                     # Helper scripts
    ├── setup-backend.sh         # Setup S3 backend
    ├── deploy.sh                # Deploy infrastructure
    └── destroy.sh               # Destroy infrastructure
```

## 🔐 Security Features

### Infrastructure Security
- ✅ **Encryption at Rest**: KMS encryption for EKS secrets and RDS
- ✅ **Encryption in Transit**: TLS for all communications
- ✅ **Network Isolation**: Private subnets for EKS nodes and RDS
- ✅ **Security Groups**: Least privilege access rules
- ✅ **VPC Flow Logs**: Network traffic monitoring
- ✅ **No Hardcoded Secrets**: Passwords generated and stored in Secrets Manager
- ✅ **IAM Roles for Service Accounts (IRSA)**: Pod-level IAM permissions
- ✅ **Multi-AZ**: High availability across availability zones

### Compliance
- ✅ **PCI-DSS Ready**: Encryption, logging, and access controls
- ✅ **Audit Logging**: CloudWatch logs for EKS and RDS
- ✅ **Backup & Recovery**: Automated RDS backups
- ✅ **Deletion Protection**: Enabled for production RDS

## 🚀 Quick Start

### Prerequisites

```bash
# Install required tools
terraform --version  # >= 1.5.0
aws --version        # >= 2.0
kubectl version      # >= 1.24
```

### 1. Configure AWS Credentials

```bash
aws configure
# Or use environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"
```

### 2. Setup Terraform Backend

```bash
cd infrastructure/scripts
chmod +x *.sh

# Create S3 bucket and DynamoDB table for state management
./setup-backend.sh dev us-east-1
./setup-backend.sh staging us-east-1
./setup-backend.sh prod us-east-1
```

### 3. Deploy Infrastructure

```bash
# Deploy development environment
./deploy.sh dev

# Deploy staging environment
./deploy.sh staging

# Deploy production environment
./deploy.sh prod
```

## 📝 Manual Deployment

### Development Environment

```bash
cd infrastructure/environments/dev

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply changes
terraform apply

# Get outputs
terraform output
```

### Configure kubectl

```bash
# Get the command from Terraform output
terraform output -raw configure_kubectl

# Or manually
aws eks update-kubeconfig --region us-east-1 --name banking-app-dev-eks

# Verify connection
kubectl get nodes
```

### Get Database Credentials

```bash
# Get secret ARN
DB_SECRET_ARN=$(terraform output -raw db_secret_arn)

# Retrieve credentials
aws secretsmanager get-secret-value \
  --secret-id $DB_SECRET_ARN \
  --query SecretString \
  --output text | jq .
```

## 🔧 Configuration

### Environment Variables

Set database password via environment variable (recommended):

```bash
export TF_VAR_db_password="your-secure-password"
```

Or use AWS Secrets Manager:

```bash
# Store password in Secrets Manager
aws secretsmanager create-secret \
  --name banking-app-db-password \
  --secret-string "your-secure-password"

# Reference in Terraform
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "banking-app-db-password"
}
```

### Customizing Environments

Edit `environments/<env>/terraform.tfvars`:

```hcl
# Example: Increase node count
node_group_config = {
  desired_size   = 5
  min_size       = 3
  max_size       = 10
  instance_types = ["t3.xlarge"]
  disk_size      = 50
  capacity_type  = "ON_DEMAND"
}
```

## 🏗️ Architecture

### Network Architecture

- **VPC**: Isolated network with CIDR 10.x.0.0/16
- **Public Subnets**: NAT Gateways, Load Balancers
- **Private Subnets**: EKS worker nodes
- **Database Subnets**: RDS instances (no internet access)
- **Multi-AZ**: Resources spread across 2 availability zones

### EKS Cluster

- **Control Plane**: Managed by AWS
- **Node Groups**: Auto-scaling worker nodes
- **Addons**: VPC-CNI, CoreDNS, kube-proxy
- **IRSA**: IAM roles for pods via OIDC

### RDS Database

- **Engine**: MySQL 8.0
- **Encryption**: KMS encryption at rest
- **Backups**: Automated daily backups
- **Multi-AZ**: High availability (staging/prod)
- **Monitoring**: Enhanced monitoring and Performance Insights

## 📊 Monitoring

### CloudWatch

- **EKS Logs**: API server, audit, authenticator logs
- **RDS Metrics**: CPU, memory, connections, storage
- **VPC Flow Logs**: Network traffic analysis
- **Container Insights**: Pod and node metrics

### Alarms

Configured alarms for:
- RDS CPU utilization > 80%
- RDS free memory < 512 MB
- RDS free storage < 10 GB
- RDS connections > 150

## 🔄 Updates and Maintenance

### Update Kubernetes Version

```bash
cd infrastructure/environments/prod

# Edit terraform.tfvars
cluster_version = "1.29"

# Apply changes
terraform apply
```

### Scale Node Group

```bash
# Edit terraform.tfvars
node_group_config = {
  desired_size = 5
  # ...
}

# Apply changes
terraform apply
```

### Update RDS Instance Class

```bash
# Edit terraform.tfvars
db_config = {
  instance_class = "db.r6g.xlarge"
  # ...
}

# Apply changes (will cause downtime for single-AZ)
terraform apply
```

## 🗑️ Cleanup

### Destroy Infrastructure

```bash
cd infrastructure/scripts

# Destroy development environment
./destroy.sh dev

# Destroy staging environment
./destroy.sh staging

# Destroy production (requires extra confirmation)
./destroy.sh prod
```

### Manual Destroy

```bash
cd infrastructure/environments/dev

# Plan destroy
terraform plan -destroy

# Destroy
terraform destroy
```

## 📋 Environment Comparison

| Feature | Dev | Staging | Prod |
|---------|-----|---------|------|
| **Nodes** | 2 | 3 | 3-10 |
| **Instance Type** | t3.medium | t3.large | t3.xlarge |
| **RDS Instance** | db.t3.small | db.t3.medium | db.r6g.large |
| **Multi-AZ RDS** | No | Yes | Yes |
| **Backup Retention** | 3 days | 7 days | 30 days |
| **Deletion Protection** | No | No | Yes |
| **Log Retention** | 3 days | 7 days | 30 days |
| **Capacity Type** | ON_DEMAND | ON_DEMAND | ON_DEMAND |

## 💰 Cost Optimization

### Development
- Use smaller instance types
- Single-AZ RDS
- Shorter backup retention
- Spot instances (optional)

### Production
- Use Reserved Instances for predictable workloads
- Enable RDS storage autoscaling
- Use Savings Plans
- Monitor with AWS Cost Explorer

### Estimated Monthly Costs

**Development**: ~$150-200/month
- EKS: $72 (cluster)
- EC2: ~$60 (2x t3.medium)
- RDS: ~$30 (db.t3.small)
- NAT Gateway: ~$30

**Production**: ~$800-1000/month
- EKS: $72 (cluster)
- EC2: ~$400 (3x t3.xlarge)
- RDS: ~$250 (db.r6g.large Multi-AZ)
- NAT Gateway: ~$60 (2 AZs)

## 🔒 Security Best Practices

### Secrets Management
- ✅ Never commit secrets to Git
- ✅ Use AWS Secrets Manager for sensitive data
- ✅ Rotate credentials regularly
- ✅ Use IAM roles instead of access keys

### Network Security
- ✅ Use private subnets for workloads
- ✅ Restrict security group rules
- ✅ Enable VPC Flow Logs
- ✅ Use AWS WAF for public endpoints

### Access Control
- ✅ Use IAM roles with least privilege
- ✅ Enable MFA for AWS accounts
- ✅ Use IRSA for pod permissions
- ✅ Audit access with CloudTrail

## 🐛 Troubleshooting

### Terraform State Lock

```bash
# If state is locked
aws dynamodb delete-item \
  --table-name terraform-state-lock-dev \
  --key '{"LockID":{"S":"banking-app-terraform-state-dev/dev/terraform.tfstate"}}'
```

### EKS Access Denied

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name banking-app-dev-eks

# Check IAM identity
aws sts get-caller-identity

# Add IAM user to aws-auth ConfigMap
kubectl edit configmap aws-auth -n kube-system
```

### RDS Connection Issues

```bash
# Test from EKS pod
kubectl run mysql-client --rm -it --image=mysql:8.0 -- bash
mysql -h <rds-endpoint> -u dbadmin -p

# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>
```

## 📚 Additional Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🤝 Contributing

1. Create a feature branch
2. Make changes
3. Test in dev environment
4. Create pull request
5. Deploy to staging
6. Deploy to production

## 📄 License

This infrastructure code is part of the Banking Application project.

---

**⚠️ Important Notes:**

1. Always test changes in dev/staging before production
2. Review Terraform plans carefully before applying
3. Keep Terraform state secure and backed up
4. Document any manual changes to infrastructure
5. Use version control for all infrastructure code



