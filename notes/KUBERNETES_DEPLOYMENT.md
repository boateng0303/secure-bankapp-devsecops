# Kubernetes Deployment Guide - Banking Application

Complete guide to deploy the Banking Application (Spring Boot Backend + Angular Frontend) on Kubernetes with external MySQL database.

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [External Database Setup](#external-database-setup)
4. [Kubernetes Resources](#kubernetes-resources)
5. [Deployment Steps](#deployment-steps)
6. [Verification](#verification)
7. [Scaling](#scaling)
8. [Monitoring](#monitoring)
9. [Troubleshooting](#troubleshooting)

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   Cloud Load Balancer                        │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  Ingress Controller (NGINX)                  │
└─────────────┬───────────────────────┬───────────────────────┘
              │                       │
              ▼                       ▼
    ┌─────────────────┐     ┌─────────────────┐
    │   Frontend      │     │    Backend      │
    │   Service       │     │    Service      │
    └────────┬────────┘     └────────┬────────┘
             │                       │
             ▼                       ▼
    ┌─────────────────┐     ┌─────────────────┐
    │  Frontend Pods  │     │  Backend Pods   │
    │   (Angular)     │     │  (Spring Boot)  │
    │  Replicas: 3    │     │  Replicas: 3    │
    └─────────────────┘     └────────┬────────┘
                                     │
                                     │ (External Connection)
                                     ▼
                            ┌─────────────────┐
                            │  MySQL Database │
                            │  (External RDS) │
                            └─────────────────┘
```

### Components

- **Namespace**: `banking-app` - Isolated environment
- **Frontend**: Angular app (3 replicas)
- **Backend**: Spring Boot API (3 replicas)
- **Ingress**: NGINX for routing and SSL
- **Database**: External MySQL (AWS RDS, Google Cloud SQL, etc.)
- **Secrets**: Database credentials, JWT secret
- **ConfigMaps**: Application configuration

---

## 📋 Prerequisites

### Required Tools

```bash
# Kubernetes cluster (1.24+)
kubectl version

# Helm (3.0+)
helm version

# Docker (for building images)
docker --version

# kubectl access to cluster
kubectl cluster-info
```

### Container Registry

You need a container registry to store your Docker images:
- **Docker Hub**: `docker.io/yourusername`
- **Google Container Registry**: `gcr.io/your-project`
- **AWS ECR**: `123456789.dkr.ecr.region.amazonaws.com`
- **Azure ACR**: `yourregistry.azurecr.io`

---

## 🗄️ External Database Setup

### Option 1: AWS RDS (MySQL)

```bash
# Create RDS instance via AWS Console or CLI
aws rds create-db-instance \
  --db-instance-identifier banking-db \
  --db-instance-class db.t3.medium \
  --engine mysql \
  --engine-version 8.0.35 \
  --master-username admin \
  --master-user-password YourSecurePassword123! \
  --allocated-storage 20 \
  --vpc-security-group-ids sg-xxxxx \
  --db-subnet-group-name your-subnet-group \
  --backup-retention-period 7 \
  --publicly-accessible false

# Get endpoint
aws rds describe-db-instances \
  --db-instance-identifier banking-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text
```

### Option 2: Google Cloud SQL

```bash
# Create Cloud SQL instance
gcloud sql instances create banking-db \
  --database-version=MYSQL_8_0 \
  --tier=db-n1-standard-2 \
  --region=us-central1 \
  --root-password=YourSecurePassword123! \
  --backup \
  --backup-start-time=03:00

# Get connection name
gcloud sql instances describe banking-db \
  --format='value(connectionName)'
```

### Option 3: Azure Database for MySQL

```bash
# Create Azure MySQL
az mysql server create \
  --resource-group banking-rg \
  --name banking-db \
  --location eastus \
  --admin-user adminuser \
  --admin-password YourSecurePassword123! \
  --sku-name GP_Gen5_2 \
  --version 8.0

# Get connection string
az mysql server show \
  --resource-group banking-rg \
  --name banking-db \
  --query fullyQualifiedDomainName \
  --output tsv
```

### Create Database and User

Connect to your database and run:

```sql
-- Create database
CREATE DATABASE banking_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create user (if needed)
CREATE USER 'banking_user'@'%' IDENTIFIED BY 'SecurePassword123!';

-- Grant privileges
GRANT ALL PRIVILEGES ON banking_db.* TO 'banking_user'@'%';
FLUSH PRIVILEGES;

-- Verify
SHOW DATABASES;
SELECT user, host FROM mysql.user WHERE user = 'banking_user';
```

### Security Group / Firewall Rules

Allow Kubernetes cluster to access database:

**AWS RDS:**
```bash
# Add security group rule to allow traffic from EKS nodes
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 3306 \
  --source-group sg-eks-nodes
```

**GCP Cloud SQL:**
```bash
# Add authorized network (Kubernetes cluster CIDR)
gcloud sql instances patch banking-db \
  --authorized-networks=10.0.0.0/8
```

**Azure:**
```bash
# Add firewall rule
az mysql server firewall-rule create \
  --resource-group banking-rg \
  --server banking-db \
  --name AllowK8s \
  --start-ip-address 10.0.0.0 \
  --end-ip-address 10.255.255.255
```

---

## 🚀 Kubernetes Resources

### 1. Namespace

```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: banking-app
  labels:
    name: banking-app
    environment: production
```

### 2. Secrets

```yaml
# secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: banking-secrets
  namespace: banking-app
type: Opaque
stringData:
  # Database credentials
  DB_HOST: "your-db-instance.region.rds.amazonaws.com"
  DB_PORT: "3306"
  DB_NAME: "banking_db"
  DB_USERNAME: "banking_user"
  DB_PASSWORD: "SecurePassword123!"
  
  # JWT Secret (generate with: openssl rand -base64 64)
  JWT_SECRET: "your-super-secret-jwt-key-min-256-bits-long-change-this-in-production"
  
  # Optional: Additional secrets
  ENCRYPTION_KEY: "your-encryption-key"
```

**Create secret from command line (more secure):**

```bash
kubectl create secret generic banking-secrets \
  --from-literal=DB_HOST=your-db-host.rds.amazonaws.com \
  --from-literal=DB_PORT=3306 \
  --from-literal=DB_NAME=banking_db \
  --from-literal=DB_USERNAME=banking_user \
  --from-literal=DB_PASSWORD='SecurePassword123!' \
  --from-literal=JWT_SECRET='your-jwt-secret-key' \
  --namespace=banking-app
```

### 3. ConfigMap

```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: banking-config
  namespace: banking-app
data:
  # Application settings
  SPRING_PROFILES_ACTIVE: "prod"
  SERVER_PORT: "8080"
  
  # CORS settings
  CORS_ALLOWED_ORIGINS: "https://your-domain.com,https://www.your-domain.com"
  
  # JWT settings
  JWT_EXPIRATION: "86400000"  # 24 hours in milliseconds
  
  # Logging
  LOGGING_LEVEL_ROOT: "INFO"
  LOGGING_LEVEL_COM_BANKING: "DEBUG"
  
  # Database pool settings
  DB_POOL_SIZE: "10"
  DB_CONNECTION_TIMEOUT: "30000"
```

### 4. Backend Deployment

```yaml
# backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: banking-backend
  namespace: banking-app
  labels:
    app: banking-backend
    tier: backend
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: banking-backend
  template:
    metadata:
      labels:
        app: banking-backend
        tier: backend
    spec:
      containers:
      - name: backend
        image: your-registry/banking-backend:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
          name: http
          protocol: TCP
        
        env:
        # Spring Boot profile
        - name: SPRING_PROFILES_ACTIVE
          valueFrom:
            configMapKeyRef:
              name: banking-config
              key: SPRING_PROFILES_ACTIVE
        
        # Database configuration from secrets
        - name: SPRING_DATASOURCE_URL
          value: "jdbc:mysql://$(DB_HOST):$(DB_PORT)/$(DB_NAME)?useSSL=true&requireSSL=true&serverTimezone=UTC"
        - name: DB_HOST
          valueFrom:
            secretKeyRef:
              name: banking-secrets
              key: DB_HOST
        - name: DB_PORT
          valueFrom:
            secretKeyRef:
              name: banking-secrets
              key: DB_PORT
        - name: DB_NAME
          valueFrom:
            secretKeyRef:
              name: banking-secrets
              key: DB_NAME
        - name: SPRING_DATASOURCE_USERNAME
          valueFrom:
            secretKeyRef:
              name: banking-secrets
              key: DB_USERNAME
        - name: SPRING_DATASOURCE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: banking-secrets
              key: DB_PASSWORD
        
        # JWT configuration
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: banking-secrets
              key: JWT_SECRET
        - name: JWT_EXPIRATION
          valueFrom:
            configMapKeyRef:
              name: banking-config
              key: JWT_EXPIRATION
        
        # CORS configuration
        - name: CORS_ALLOWED_ORIGINS
          valueFrom:
            configMapKeyRef:
              name: banking-config
              key: CORS_ALLOWED_ORIGINS
        
        # Resource limits
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        
        # Health checks
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        
        # Startup probe (for slow starting apps)
        startupProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 0
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 30
      
      # Image pull secrets (if using private registry)
      # imagePullSecrets:
      # - name: registry-credentials
```

### 5. Backend Service

```yaml
# backend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: banking-backend-service
  namespace: banking-app
  labels:
    app: banking-backend
spec:
  type: ClusterIP
  selector:
    app: banking-backend
  ports:
  - name: http
    port: 8080
    targetPort: 8080
    protocol: TCP
  sessionAffinity: None
```

### 6. Frontend Deployment

```yaml
# frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: banking-frontend
  namespace: banking-app
  labels:
    app: banking-frontend
    tier: frontend
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: banking-frontend
  template:
    metadata:
      labels:
        app: banking-frontend
        tier: frontend
    spec:
      containers:
      - name: frontend
        image: your-registry/banking-frontend:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 80
          name: http
          protocol: TCP
        
        # Resource limits
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        
        # Health checks
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
      
      # Image pull secrets (if using private registry)
      # imagePullSecrets:
      # - name: registry-credentials
```

### 7. Frontend Service

```yaml
# frontend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: banking-frontend-service
  namespace: banking-app
  labels:
    app: banking-frontend
spec:
  type: ClusterIP
  selector:
    app: banking-frontend
  ports:
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
  sessionAffinity: None
```

### 8. Ingress

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: banking-ingress
  namespace: banking-app
  annotations:
    # Ingress class
    kubernetes.io/ingress.class: "nginx"
    
    # SSL/TLS
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    
    # CORS
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://your-domain.com,https://www.your-domain.com"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE, OPTIONS"
    nginx.ingress.kubernetes.io/cors-allow-headers: "DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization"
    nginx.ingress.kubernetes.io/cors-allow-credentials: "true"
    
    # Rate limiting
    nginx.ingress.kubernetes.io/limit-rps: "100"
    nginx.ingress.kubernetes.io/limit-burst-multiplier: "2"
    
    # Request size
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    
    # Timeouts
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
    
    # Security headers
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Frame-Options: DENY";
      more_set_headers "X-Content-Type-Options: nosniff";
      more_set_headers "X-XSS-Protection: 1; mode=block";
      more_set_headers "Referrer-Policy: strict-origin-when-cross-origin";

spec:
  tls:
  - hosts:
    - your-domain.com
    - www.your-domain.com
    - api.your-domain.com
    secretName: banking-tls-secret
  
  rules:
  # Frontend - main domain
  - host: your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: banking-frontend-service
            port:
              number: 80
  
  # Frontend - www subdomain
  - host: www.your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: banking-frontend-service
            port:
              number: 80
  
  # Backend API - api subdomain
  - host: api.your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: banking-backend-service
            port:
              number: 8080
```

### 9. Horizontal Pod Autoscaler (HPA)

```yaml
# hpa-backend.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: banking-backend-hpa
  namespace: banking-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: banking-backend
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
      - type: Pods
        value: 2
        periodSeconds: 30
      selectPolicy: Max
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: banking-frontend-hpa
  namespace: banking-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: banking-frontend
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### 10. Network Policy (Optional - for security)

```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: banking-network-policy
  namespace: banking-app
spec:
  podSelector:
    matchLabels:
      app: banking-backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Allow traffic from frontend
  - from:
    - podSelector:
        matchLabels:
          app: banking-frontend
    ports:
    - protocol: TCP
      port: 8080
  # Allow traffic from ingress controller
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  egress:
  # Allow DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  # Allow external database
  - to:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 3306
  # Allow HTTPS (for external APIs)
  - to:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 443
```

### 11. PodDisruptionBudget

```yaml
# pdb.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: banking-backend-pdb
  namespace: banking-app
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: banking-backend
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: banking-frontend-pdb
  namespace: banking-app
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: banking-frontend
```

---

## 🚀 Deployment Steps

### Step 1: Build Docker Images

#### Backend Dockerfile

```dockerfile
# backend/Dockerfile
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

# Create non-root user
RUN addgroup -g 1001 -S appuser && adduser -u 1001 -S appuser -G appuser
USER appuser

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "-Dspring.profiles.active=prod", "app.jar"]
```

#### Frontend Dockerfile

```dockerfile
# banking-frontend/Dockerfile
# Stage 1: Build Angular app
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build -- --configuration production

# Stage 2: Serve with Nginx
FROM nginx:1.25-alpine
COPY --from=build /app/dist/banking-frontend /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create non-root user
RUN addgroup -g 1001 -S appuser && adduser -u 1001 -S appuser -G appuser
RUN chown -R appuser:appuser /usr/share/nginx/html /var/cache/nginx /var/run /var/log/nginx
USER appuser

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

#### Frontend Nginx Config

```nginx
# banking-frontend/nginx.conf
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;

    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Angular routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
```

#### Build and Push Images

```bash
# Backend
cd backend
docker build -t your-registry/banking-backend:latest .
docker push your-registry/banking-backend:latest

# Frontend
cd ../banking-frontend
docker build -t your-registry/banking-frontend:latest .
docker push your-registry/banking-frontend:latest
```

### Step 2: Install Prerequisites

#### Install NGINX Ingress Controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.metrics.enabled=true

# Wait for external IP
kubectl get svc -n ingress-nginx -w
```

#### Install cert-manager (for SSL)

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --for=condition=Available --timeout=300s deployment/cert-manager -n cert-manager
```

#### Create Let's Encrypt ClusterIssuer

```yaml
# letsencrypt-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com  # ⚠️ Change this!
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

```bash
kubectl apply -f letsencrypt-issuer.yaml
```

### Step 3: Deploy Application

```bash
# Create namespace
kubectl apply -f namespace.yaml

# Create secrets (use command line for security)
kubectl create secret generic banking-secrets \
  --from-literal=DB_HOST=your-db-host.rds.amazonaws.com \
  --from-literal=DB_PORT=3306 \
  --from-literal=DB_NAME=banking_db \
  --from-literal=DB_USERNAME=banking_user \
  --from-literal=DB_PASSWORD='YourSecurePassword123!' \
  --from-literal=JWT_SECRET='your-jwt-secret-min-256-bits' \
  --namespace=banking-app

# Create ConfigMap
kubectl apply -f configmap.yaml

# Deploy backend
kubectl apply -f backend-deployment.yaml
kubectl apply -f backend-service.yaml

# Deploy frontend
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml

# Deploy Ingress
kubectl apply -f ingress.yaml

# Deploy HPA
kubectl apply -f hpa-backend.yaml

# Deploy PDB
kubectl apply -f pdb.yaml

# Optional: Network Policy
kubectl apply -f network-policy.yaml
```

### Step 4: Configure DNS

```bash
# Get Ingress external IP
kubectl get svc ingress-nginx-controller -n ingress-nginx

# Configure DNS records (in your DNS provider):
# A record: your-domain.com → <EXTERNAL-IP>
# A record: www.your-domain.com → <EXTERNAL-IP>
# A record: api.your-domain.com → <EXTERNAL-IP>
```

### Step 5: Update Frontend Environment

Update `src/environments/environment.prod.ts`:

```typescript
export const environment = {
  production: true,
  apiUrl: 'https://api.your-domain.com/api'
};
```

Rebuild and redeploy frontend:

```bash
cd banking-frontend
npm run build -- --configuration production
docker build -t your-registry/banking-frontend:latest .
docker push your-registry/banking-frontend:latest
kubectl rollout restart deployment banking-frontend -n banking-app
```

---

## ✅ Verification

### Check All Resources

```bash
# Check namespace
kubectl get ns banking-app

# Check all resources
kubectl get all -n banking-app

# Check secrets
kubectl get secrets -n banking-app

# Check configmaps
kubectl get configmap -n banking-app

# Check ingress
kubectl get ingress -n banking-app
kubectl describe ingress banking-ingress -n banking-app
```

### Check Pods

```bash
# List pods
kubectl get pods -n banking-app

# Check pod logs
kubectl logs -f deployment/banking-backend -n banking-app
kubectl logs -f deployment/banking-frontend -n banking-app

# Describe pod
kubectl describe pod <pod-name> -n banking-app
```

### Check Services

```bash
# List services
kubectl get svc -n banking-app

# Test backend service internally
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n banking-app -- \
  curl http://banking-backend-service:8080/actuator/health
```

### Check Ingress

```bash
# Get Ingress details
kubectl describe ingress banking-ingress -n banking-app

# Check SSL certificate
kubectl get certificate -n banking-app
kubectl describe certificate banking-tls-secret -n banking-app

# Test endpoints
curl https://your-domain.com
curl https://api.your-domain.com/actuator/health
```

### Check HPA

```bash
# Check HPA status
kubectl get hpa -n banking-app

# Watch HPA
kubectl get hpa -n banking-app -w
```

### Application Health

```bash
# Backend health
curl https://api.your-domain.com/actuator/health

# Frontend health
curl https://your-domain.com/

# Test login
curl -X POST https://api.your-domain.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'
```

---

## 📈 Scaling

### Manual Scaling

```bash
# Scale backend
kubectl scale deployment banking-backend --replicas=5 -n banking-app

# Scale frontend
kubectl scale deployment banking-frontend --replicas=5 -n banking-app

# Check scaling
kubectl get pods -n banking-app -w
```

### Auto-scaling (HPA)

HPA automatically scales based on CPU/memory:

```bash
# Check HPA status
kubectl get hpa -n banking-app

# Describe HPA
kubectl describe hpa banking-backend-hpa -n banking-app

# Generate load to test autoscaling
kubectl run -it --rm load-generator --image=busybox --restart=Never -n banking-app -- \
  /bin/sh -c "while true; do wget -q -O- http://banking-backend-service:8080/api/dashboard; done"
```

### Cluster Autoscaling

Enable cluster autoscaler for node-level scaling:

**AWS EKS:**
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
```

**GKE:**
```bash
gcloud container clusters update banking-cluster \
  --enable-autoscaling \
  --min-nodes=3 \
  --max-nodes=10
```

---

## 📊 Monitoring

### Install Prometheus & Grafana

```bash
# Add Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Default credentials: admin / prom-operator
```

### View Logs

```bash
# Real-time logs
kubectl logs -f deployment/banking-backend -n banking-app

# Logs from all pods
kubectl logs -l app=banking-backend -n banking-app --tail=100

# Previous container logs (if crashed)
kubectl logs <pod-name> -n banking-app --previous
```

### Metrics

```bash
# Top pods
kubectl top pods -n banking-app

# Top nodes
kubectl top nodes

# Resource usage
kubectl describe node <node-name>
```

---

## 🐛 Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl get pods -n banking-app

# Describe pod
kubectl describe pod <pod-name> -n banking-app

# Check events
kubectl get events -n banking-app --sort-by='.lastTimestamp'

# Check logs
kubectl logs <pod-name> -n banking-app
```

### Database Connection Issues

```bash
# Test database connectivity from pod
kubectl run -it --rm mysql-client --image=mysql:8.0 --restart=Never -n banking-app -- \
  mysql -h your-db-host.rds.amazonaws.com -u banking_user -p

# Check secrets
kubectl get secret banking-secrets -n banking-app -o yaml

# Check environment variables in pod
kubectl exec -it <pod-name> -n banking-app -- env | grep DB
```

### Ingress Not Working

```bash
# Check Ingress Controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Check Ingress resource
kubectl describe ingress banking-ingress -n banking-app

# Test without Ingress
kubectl port-forward -n banking-app svc/banking-backend-service 8080:8080
curl http://localhost:8080/actuator/health
```

### SSL Certificate Issues

```bash
# Check certificate
kubectl get certificate -n banking-app
kubectl describe certificate banking-tls-cert -n banking-app

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Check certificate request
kubectl get certificaterequest -n banking-app
kubectl describe certificaterequest <name> -n banking-app

# Manual certificate check
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

### High Memory/CPU Usage

```bash
# Check resource usage
kubectl top pods -n banking-app

# Increase resources
kubectl set resources deployment banking-backend -n banking-app \
  --requests=cpu=500m,memory=1Gi \
  --limits=cpu=1000m,memory=2Gi

# Check HPA
kubectl get hpa -n banking-app
```

---

## 🔄 Updates and Rollbacks

### Rolling Update

```bash
# Update image
kubectl set image deployment/banking-backend \
  backend=your-registry/banking-backend:v2.0 \
  -n banking-app

# Watch rollout
kubectl rollout status deployment/banking-backend -n banking-app

# Check rollout history
kubectl rollout history deployment/banking-backend -n banking-app
```

### Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/banking-backend -n banking-app

# Rollback to specific revision
kubectl rollout undo deployment/banking-backend --to-revision=2 -n banking-app

# Check rollout history
kubectl rollout history deployment/banking-backend -n banking-app
```

---

## 🗑️ Cleanup

```bash
# Delete all resources
kubectl delete namespace banking-app

# Delete Ingress Controller
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete namespace ingress-nginx

# Delete cert-manager
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Delete monitoring
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
```

---

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [cert-manager](https://cert-manager.io/docs/)
- [Helm Charts](https://helm.sh/docs/)
- [Spring Boot on Kubernetes](https://spring.io/guides/gs/spring-boot-kubernetes/)

---

## 🎯 Production Checklist

- [ ] External database configured and accessible
- [ ] Secrets created securely (not in YAML files)
- [ ] SSL certificates configured
- [ ] DNS records pointing to Ingress
- [ ] Resource limits set appropriately
- [ ] Health checks configured
- [ ] HPA configured for autoscaling
- [ ] PDB configured for high availability
- [ ] Monitoring and logging set up
- [ ] Backup strategy for database
- [ ] Disaster recovery plan
- [ ] Security scanning of container images
- [ ] Network policies configured
- [ ] RBAC configured
- [ ] Regular security updates scheduled

---

**Your Banking Application is now production-ready on Kubernetes!** 🚀

