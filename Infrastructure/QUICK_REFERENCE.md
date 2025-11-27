# Quick Reference Guide

Quick commands and references for managing the EKS infrastructure.

## 🚀 Quick Start Commands

### Deploy Infrastructure

```bash
# Development
cd infrastructure/scripts
./setup-backend.sh dev us-east-1
./deploy.sh dev

# Production
./setup-backend.sh prod us-east-1
./deploy.sh prod
```

### Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name banking-app-<env>-eks
kubectl get nodes
```

### Get Database Credentials

```bash
aws secretsmanager get-secret-value \
  --secret-id $(cd infrastructure/environments/<env> && terraform output -raw db_secret_arn) \
  --query SecretString --output text | jq .
```

## 📝 Common Terraform Commands

```bash
# Initialize
terraform init

# Validate
terraform validate

# Format
terraform fmt -recursive

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Destroy
terraform destroy

# Show outputs
terraform output

# Show state
terraform show

# List resources
terraform state list

# Refresh state
terraform refresh
```

## 🔍 Kubectl Commands

```bash
# Cluster info
kubectl cluster-info
kubectl get nodes
kubectl top nodes

# Namespaces
kubectl get namespaces
kubectl create namespace banking-app

# Pods
kubectl get pods -A
kubectl get pods -n banking-app
kubectl describe pod <pod-name> -n banking-app
kubectl logs <pod-name> -n banking-app
kubectl logs -f <pod-name> -n banking-app

# Services
kubectl get svc -A
kubectl get svc -n banking-app
kubectl describe svc <service-name> -n banking-app

# Deployments
kubectl get deployments -A
kubectl scale deployment <name> --replicas=5 -n banking-app
kubectl rollout status deployment/<name> -n banking-app
kubectl rollout restart deployment/<name> -n banking-app

# Secrets
kubectl get secrets -n banking-app
kubectl describe secret <secret-name> -n banking-app
kubectl create secret generic <name> --from-literal=key=value

# ConfigMaps
kubectl get configmaps -A
kubectl describe configmap <name> -n banking-app

# Ingress
kubectl get ingress -A
kubectl describe ingress <name> -n banking-app

# Events
kubectl get events -A --sort-by='.lastTimestamp'
kubectl get events -n banking-app --sort-by='.lastTimestamp'

# Execute commands in pod
kubectl exec -it <pod-name> -n banking-app -- bash
kubectl exec -it <pod-name> -n banking-app -- env

# Port forwarding
kubectl port-forward -n banking-app svc/<service-name> 8080:8080

# Copy files
kubectl cp <pod-name>:/path/to/file ./local-file -n banking-app
kubectl cp ./local-file <pod-name>:/path/to/file -n banking-app
```

## 🗄️ AWS CLI Commands

### EKS

```bash
# List clusters
aws eks list-clusters

# Describe cluster
aws eks describe-cluster --name banking-app-dev-eks

# List node groups
aws eks list-nodegroups --cluster-name banking-app-dev-eks

# Describe node group
aws eks describe-nodegroup \
  --cluster-name banking-app-dev-eks \
  --nodegroup-name banking-app-dev-eks-node-group

# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name banking-app-dev-eks
```

### RDS

```bash
# List DB instances
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]' \
  --output table

# Describe specific instance
aws rds describe-db-instances \
  --db-instance-identifier banking-app-dev-eks-db

# List snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier banking-app-dev-eks-db

# Create snapshot
aws rds create-db-snapshot \
  --db-instance-identifier banking-app-dev-eks-db \
  --db-snapshot-identifier banking-app-dev-manual-snapshot-$(date +%Y%m%d)

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier banking-app-dev-eks-db-restored \
  --db-snapshot-identifier <snapshot-id>
```

### VPC

```bash
# List VPCs
aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=banking-app" \
  --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# List subnets
aws ec2 describe-subnets \
  --filters "Name=tag:Project,Values=banking-app" \
  --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# List security groups
aws ec2 describe-security-groups \
  --filters "Name=tag:Project,Values=banking-app" \
  --query 'SecurityGroups[*].[GroupId,GroupName,Description]' \
  --output table
```

### Secrets Manager

```bash
# List secrets
aws secretsmanager list-secrets \
  --query 'SecretList[*].[Name,ARN]' \
  --output table

# Get secret value
aws secretsmanager get-secret-value \
  --secret-id banking-app-dev-eks-db-password \
  --query SecretString \
  --output text

# Update secret
aws secretsmanager update-secret \
  --secret-id banking-app-dev-eks-db-password \
  --secret-string "new-password"

# Rotate secret
aws secretsmanager rotate-secret \
  --secret-id banking-app-dev-eks-db-password
```

### CloudWatch

```bash
# List log groups
aws logs describe-log-groups \
  --log-group-name-prefix /aws/eks/banking-app

# Tail logs
aws logs tail /aws/eks/banking-app-dev-eks/cluster --follow

# Get log events
aws logs get-log-events \
  --log-group-name /aws/eks/banking-app-dev-eks/cluster \
  --log-stream-name <stream-name>

# List alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix banking-app-dev

# Get metric statistics
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=banking-app-dev-eks-db \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

## 🔧 Troubleshooting Commands

### Check Pod Status

```bash
# Get pod status
kubectl get pods -n banking-app

# Describe pod
kubectl describe pod <pod-name> -n banking-app

# Get pod logs
kubectl logs <pod-name> -n banking-app

# Get previous pod logs (if crashed)
kubectl logs <pod-name> -n banking-app --previous

# Get events
kubectl get events -n banking-app --sort-by='.lastTimestamp'
```

### Debug Networking

```bash
# Test DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Test connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://service-name:port

# Check network policies
kubectl get networkpolicies -A

# Test database connection
kubectl run -it --rm mysql-client --image=mysql:8.0 --restart=Never -- bash
```

### Check Resource Usage

```bash
# Node resources
kubectl top nodes

# Pod resources
kubectl top pods -A
kubectl top pods -n banking-app

# Describe node
kubectl describe node <node-name>

# Get resource quotas
kubectl get resourcequotas -A
```

### Check Cluster Health

```bash
# Component status
kubectl get componentstatuses

# Node conditions
kubectl get nodes -o json | jq '.items[].status.conditions'

# System pods
kubectl get pods -n kube-system

# Check API server
kubectl get --raw /healthz
kubectl get --raw /readyz
```

## 📊 Monitoring Commands

### Metrics Server

```bash
# Install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Check metrics
kubectl top nodes
kubectl top pods -A
```

### Prometheus (if installed)

```bash
# Port forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus-server 9090:80

# Access at http://localhost:9090
```

### Grafana (if installed)

```bash
# Port forward to Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80

# Access at http://localhost:3000
```

## 🔐 Security Commands

### Check RBAC

```bash
# List roles
kubectl get roles -A

# List cluster roles
kubectl get clusterroles

# Check permissions
kubectl auth can-i create pods --namespace=banking-app
kubectl auth can-i '*' '*' --all-namespaces

# Who can
kubectl auth can-i --list --namespace=banking-app
```

### Scan for Vulnerabilities

```bash
# Scan with kube-bench
kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job.yaml
kubectl logs -l app=kube-bench

# Scan with Trivy
trivy k8s --report summary cluster
```

### Check Pod Security

```bash
# Get pod security policies
kubectl get psp

# Check security context
kubectl get pod <pod-name> -n banking-app -o jsonpath='{.spec.securityContext}'
```

## 💾 Backup & Restore

### Velero (if installed)

```bash
# Create backup
velero backup create banking-app-backup --include-namespaces banking-app

# List backups
velero backup get

# Restore from backup
velero restore create --from-backup banking-app-backup

# Schedule backups
velero schedule create daily-backup --schedule="0 2 * * *" --include-namespaces banking-app
```

### RDS Snapshots

```bash
# Create snapshot
aws rds create-db-snapshot \
  --db-instance-identifier banking-app-dev-eks-db \
  --db-snapshot-identifier manual-snapshot-$(date +%Y%m%d)

# List snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier banking-app-dev-eks-db

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier banking-app-dev-eks-db-restored \
  --db-snapshot-identifier <snapshot-id>
```

## 🔄 Update & Rollback

### Update Deployment

```bash
# Update image
kubectl set image deployment/<name> container=new-image:tag -n banking-app

# Watch rollout
kubectl rollout status deployment/<name> -n banking-app

# Check history
kubectl rollout history deployment/<name> -n banking-app
```

### Rollback Deployment

```bash
# Rollback to previous version
kubectl rollout undo deployment/<name> -n banking-app

# Rollback to specific revision
kubectl rollout undo deployment/<name> --to-revision=2 -n banking-app
```

### Update Infrastructure

```bash
cd infrastructure/environments/<env>

# Plan update
terraform plan -out=tfplan

# Apply update
terraform apply tfplan

# Update specific resource
terraform apply -target=module.eks.aws_eks_cluster.main
```

## 📈 Scaling Commands

### Manual Scaling

```bash
# Scale deployment
kubectl scale deployment <name> --replicas=5 -n banking-app

# Scale node group
aws eks update-nodegroup-config \
  --cluster-name banking-app-dev-eks \
  --nodegroup-name banking-app-dev-eks-node-group \
  --scaling-config desiredSize=5
```

### Auto Scaling

```bash
# Create HPA
kubectl autoscale deployment <name> \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n banking-app

# Check HPA
kubectl get hpa -n banking-app

# Describe HPA
kubectl describe hpa <name> -n banking-app
```

## 🗑️ Cleanup Commands

### Delete Resources

```bash
# Delete pod
kubectl delete pod <pod-name> -n banking-app

# Delete deployment
kubectl delete deployment <name> -n banking-app

# Delete namespace (deletes all resources in it)
kubectl delete namespace banking-app

# Delete stuck resources
kubectl delete pod <pod-name> -n banking-app --grace-period=0 --force
```

### Destroy Infrastructure

```bash
cd infrastructure/scripts
./destroy.sh <env>

# Or manually
cd infrastructure/environments/<env>
terraform destroy
```

## 📞 Emergency Commands

### Force Delete Namespace

```bash
kubectl get namespace banking-app -o json \
  | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
  | kubectl replace --raw /api/v1/namespaces/banking-app/finalize -f -
```

### Drain Node

```bash
# Drain node for maintenance
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Uncordon node
kubectl uncordon <node-name>
```

### Emergency Database Access

```bash
# Connect directly to RDS (if security group allows)
mysql -h <rds-endpoint> -u dbadmin -p

# Or via bastion/jump host
ssh -L 3306:<rds-endpoint>:3306 ec2-user@<bastion-ip>
mysql -h 127.0.0.1 -u dbadmin -p
```

## 📚 Useful Aliases

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Kubectl aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias kex='kubectl exec -it'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'

# Terraform aliases
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfo='terraform output'

# AWS aliases
alias awseks='aws eks'
alias awsrds='aws rds'
alias awsec2='aws ec2'

# Context switching
alias kctx='kubectl config use-context'
alias kns='kubectl config set-context --current --namespace'
```

---

**Keep this guide handy for quick reference!** 📖

