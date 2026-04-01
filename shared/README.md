# Shared Infrastructure Resources

This folder contains cluster-wide Kubernetes resources that are shared across the banking application. These resources provide the foundational infrastructure for routing, TLS, secrets management, and application configuration.

> **Important**: This project uses **Kubernetes Gateway API** with **Envoy Gateway** as the ingress controller. The upstream kubernetes/ingress-nginx controller reached end-of-life in March 2026 and has been replaced with the modern Gateway API standard.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Resources](#resources)
  - [Namespace](#namespace)
  - [Gateway](#gateway)
  - [HTTPRoute](#httproute)
  - [Cluster Issuer](#cluster-issuer)
  - [ConfigMap](#configmap)
  - [Secret Provider Class](#secret-provider-class)
- [Installation](#installation)
- [CI/CD Pipeline](#cicd-pipeline)
- [DNS Configuration](#dns-configuration)
- [Azure Key Vault Setup](#azure-key-vault-setup)
- [Migration from Ingress-Nginx](#migration-from-ingress-nginx)
- [Troubleshooting](#troubleshooting)

---

## Overview

```
shared/
├── README.md                    # This documentation
├── install-prerequisites.sh     # One-time cluster setup script
├── namespace.yaml               # Banking namespace
├── gateway.yaml                 # Gateway API Gateway resource
├── httproute.yaml               # HTTPRoute for traffic routing
├── cluster-issuer.yaml          # Let's Encrypt TLS issuer (Gateway API)
├── configmap.yaml               # Application configuration
└── secret-providerclass.yaml    # Azure Key Vault integration
```

| Resource | Purpose |
|----------|---------|
| **Namespace** | Isolates banking application resources |
| **Gateway** | Entry point for external traffic (replaces Ingress) |
| **HTTPRoute** | Routes traffic to frontend/backend services |
| **ClusterIssuer** | Automatically provisions TLS certificates |
| **ConfigMap** | Non-sensitive application configuration |
| **SecretProviderClass** | Pulls secrets from Azure Key Vault |

---

## Architecture

```
                              Internet
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        DNS: kwasiboateng.lol                         │
│                              │                                       │
│                              ▼                                       │
│              ┌───────────────────────────────┐                      │
│              │       Envoy Gateway           │                      │
│              │   (Gateway API Controller)    │                      │
│              │   TLS Termination via         │                      │
│              │   cert-manager + Let's Encrypt│                      │
│              └───────────────┬───────────────┘                      │
│                              │                                       │
│                      ┌───────┴───────┐                              │
│                      │   Gateway     │                              │
│                      │ (app-gateway) │                              │
│                      └───────┬───────┘                              │
│                              │                                       │
│              ┌───────────────┴───────────────┐                      │
│              │         HTTPRoutes            │                      │
│              └───────────────┬───────────────┘                      │
│                              │                                       │
│         ┌────────────────────┴────────────────────┐                 │
│         │                                         │                 │
│         ▼                                         ▼                 │
│   ┌───────────┐                           ┌───────────────┐        │
│   │  Path: /  │                           │  Path: /api   │        │
│   └─────┬─────┘                           └───────┬───────┘        │
│         │                                         │                 │
│         ▼                                         ▼                 │
│   ┌───────────────┐                       ┌───────────────┐        │
│   │frontend-stable│                       │backend-stable │        │
│   │   Port: 80    │                       │   Port: 8080  │        │
│   └───────────────┘                       └───────────────┘        │
│                                                                      │
│   Namespace: banking                                                │
│                                                                      │
│   ┌──────────────────────────────────────────────────────────┐     │
│   │                    ConfigMap                              │     │
│   │  SPRING_PROFILES_ACTIVE, CORS, JWT_EXPIRATION, etc.      │     │
│   └──────────────────────────────────────────────────────────┘     │
│                                                                      │
│   ┌──────────────────────────────────────────────────────────┐     │
│   │               SecretProviderClass                         │     │
│   │                      │                                    │     │
│   │                      ▼                                    │     │
│   │              Azure Key Vault                              │     │
│   │        (db-username, db-password, jwt-secret)            │     │
│   └──────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

Before deploying shared resources, you must install the cluster prerequisites.

### Required Components

| Component | Purpose | Version |
|-----------|---------|---------|
| **Gateway API CRDs** | Standard Kubernetes API for ingress | v1.2.0 |
| **Envoy Gateway** | Gateway API implementation | v1.2.0 |
| **cert-manager** | TLS certificate automation | v1.14.0 |
| **CSI Secrets Store Driver** | Azure Key Vault integration | Latest |

### Installation Script

Run once after creating your AKS cluster:

```bash
# Make executable
chmod +x shared/install-prerequisites.sh

# Run the script
./shared/install-prerequisites.sh
```

### What the Script Installs

```bash
# 1. Gateway API CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml

# 2. Envoy Gateway
helm upgrade --install envoy-gateway envoy-gateway/envoy-gateway \
  --namespace envoy-gateway-system \
  --create-namespace \
  --version 1.2.0

# 3. cert-manager (with Gateway API support)
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.14.0 \
  --set installCRDs=true \
  --set "extraArgs={--feature-gates=ExperimentalGatewayAPISupport=true}"

# 4. CSI Secrets Store Driver for Azure
helm upgrade --install csi-secrets-store csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --namespace kube-system
```

### Verify Installation

```bash
# Check Gateway API CRDs
kubectl get crd | grep gateway

# Check Envoy Gateway
kubectl get pods -n envoy-gateway-system

# Check cert-manager
kubectl get pods -n cert-manager

# Check CSI driver
kubectl get pods -n kube-system | grep csi
```

---

## Resources

### Namespace

**File:** `namespace.yaml`

Creates an isolated namespace for all banking application resources.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: banking
```

**Purpose:**
- Resource isolation
- RBAC boundary
- Resource quota management
- Network policy scope

**Usage:**
```bash
kubectl apply -f shared/namespace.yaml
kubectl get namespace banking
```

---

### Gateway

**File:** `gateway.yaml`

Defines the entry point for external traffic using the Gateway API.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: app-gateway
  namespace: banking
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  gatewayClassName: envoy
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    hostname: kwasiboateng.lol
  - name: https
    protocol: HTTPS
    port: 443
    hostname: kwasiboateng.lol
    tls:
      mode: Terminate
      certificateRefs:
      - name: app-tls-secret
```

**Listeners:**

| Name | Port | Protocol | Purpose |
|------|------|----------|---------|
| `http` | 80 | HTTP | Redirects to HTTPS |
| `https` | 443 | HTTPS | TLS-terminated traffic |

**Key Features:**
- Automatic TLS certificate via cert-manager annotation
- HTTP to HTTPS redirect included
- Uses Envoy as the data plane

**Verify:**
```bash
kubectl get gateway -n banking
kubectl describe gateway app-gateway -n banking

# Get External IP
kubectl get gateway app-gateway -n banking -o jsonpath='{.status.addresses[0].value}'
```

---

### HTTPRoute

**File:** `httproute.yaml`

Routes external traffic to internal services based on path matching.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: backend-route
  namespace: banking
spec:
  parentRefs:
  - name: app-gateway
    sectionName: https
  hostnames:
  - kwasiboateng.lol
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api
    backendRefs:
    - name: backend-stable
      port: 8080
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: frontend-route
  namespace: banking
spec:
  parentRefs:
  - name: app-gateway
    sectionName: https
  hostnames:
  - kwasiboateng.lol
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: frontend-stable
      port: 80
```

**Routing Rules:**

| Route | Path | Service | Port | Description |
|-------|------|---------|------|-------------|
| `backend-route` | `/api` | `backend-stable` | 8080 | Spring Boot backend |
| `frontend-route` | `/` | `frontend-stable` | 80 | Angular frontend |

**Verify:**
```bash
kubectl get httproute -n banking
kubectl describe httproute backend-route -n banking
kubectl describe httproute frontend-route -n banking
```

---

### Cluster Issuer

**File:** `cluster-issuer.yaml`

Configures Let's Encrypt for automatic TLS certificate provisioning using Gateway API.

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: boatengkwasi0303@gmail.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
    - http01:
        gatewayHTTPRoute:
          parentRefs:
          - name: app-gateway
            namespace: banking
            kind: Gateway
```

**How It Works with Gateway API:**

```
1. Gateway created with cert-manager annotation
2. cert-manager detects new Gateway/HTTPRoute
3. cert-manager requests certificate from Let's Encrypt
4. Let's Encrypt sends HTTP-01 challenge
5. cert-manager creates temporary HTTPRoute to respond
6. Let's Encrypt verifies domain ownership
7. Certificate issued and stored in 'app-tls-secret'
8. cert-manager auto-renews before expiry (30 days)
```

**Verify:**
```bash
kubectl get clusterissuer
kubectl describe clusterissuer letsencrypt-prod

# Check certificate status
kubectl get certificate -n banking
kubectl describe certificate app-tls-secret -n banking
```

---

### ConfigMap

**File:** `configmap.yaml`

Stores non-sensitive application configuration.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: banking-config
  namespace: banking
data:
  SPRING_PROFILES_ACTIVE: "prod"
  SERVER_PORT: "8080"
  CORS_ALLOWED_ORIGINS: "https://kwasiboateng.lol"
  JWT_EXPIRATION: "86400000"
  LOGGING_LEVEL_ROOT: "INFO"
  LOGGING_LEVEL_COM_BANKING: "DEBUG"
  DB_POOL_SIZE: "10"
  DB_CONNECTION_TIMEOUT: "30000"
```

**Configuration Values:**

| Key | Value | Description |
|-----|-------|-------------|
| `SPRING_PROFILES_ACTIVE` | `prod` | Activates production Spring profile |
| `SERVER_PORT` | `8080` | Backend server port |
| `CORS_ALLOWED_ORIGINS` | `https://kwasiboateng.lol` | Allowed CORS origins |
| `JWT_EXPIRATION` | `86400000` | Token expiry (24 hours in ms) |
| `LOGGING_LEVEL_ROOT` | `INFO` | Root logging level |
| `LOGGING_LEVEL_COM_BANKING` | `DEBUG` | App logging level |
| `DB_POOL_SIZE` | `10` | Database connection pool size |
| `DB_CONNECTION_TIMEOUT` | `30000` | DB connection timeout (30s) |

**Usage in Deployment:**
```yaml
spec:
  containers:
  - name: backend
    envFrom:
    - configMapRef:
        name: banking-config
```

**Verify:**
```bash
kubectl get configmap banking-config -n banking
kubectl describe configmap banking-config -n banking
```

---

### Secret Provider Class

**File:** `secret-providerclass.yaml`

Integrates Azure Key Vault with Kubernetes using CSI driver.

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault-secrets
  namespace: banking
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: "${MANAGED_IDENTITY_CLIENT_ID}"
    keyvaultName: "${KEYVAULT_NAME}"
    tenantId: "${AZURE_TENANT_ID}"
    objects: |
      array:
        - |
          objectName: db-username
          objectType: secret
        - |
          objectName: db-password
          objectType: secret
        - |
          objectName: jwt-secret
          objectType: secret
  secretObjects:
  - secretName: app-secrets
    type: Opaque
    data:
    - objectName: db-username
      key: DB_USERNAME
    - objectName: db-password
      key: DB_PASSWORD
    - objectName: jwt-secret
      key: JWT_SECRET
```

**Placeholders (substituted by CI/CD):**

| Placeholder | GitHub Secret | Description |
|-------------|---------------|-------------|
| `${MANAGED_IDENTITY_CLIENT_ID}` | `MANAGED_IDENTITY_CLIENT_ID` | AKS managed identity |
| `${KEYVAULT_NAME}` | `KEYVAULT_NAME` | Azure Key Vault name |
| `${AZURE_TENANT_ID}` | `AZURE_TENANT_ID` | Azure tenant ID |

**Secrets Mapped:**

| Key Vault Secret | K8s Secret Key | Description |
|------------------|----------------|-------------|
| `db-username` | `DB_USERNAME` | Database username |
| `db-password` | `DB_PASSWORD` | Database password |
| `jwt-secret` | `JWT_SECRET` | JWT signing key |

---

## Installation

### Deployment Order

```bash
# 1. Install prerequisites (one-time)
./shared/install-prerequisites.sh

# 2. Create namespace
kubectl apply -f shared/namespace.yaml

# 3. Deploy cluster issuer
kubectl apply -f shared/cluster-issuer.yaml

# 4. Deploy configmap
kubectl apply -f shared/configmap.yaml

# 5. Deploy secret provider class (after envsubst)
envsubst < shared/secret-providerclass.yaml | kubectl apply -f -

# 6. Deploy Gateway
kubectl apply -f shared/gateway.yaml

# 7. Deploy HTTPRoutes
kubectl apply -f shared/httproute.yaml
```

### Verify All Resources

```bash
# Namespace
kubectl get namespace banking

# Gateway
kubectl get gateway -n banking

# HTTPRoutes
kubectl get httproute -n banking

# ConfigMap
kubectl get configmap -n banking

# ClusterIssuer
kubectl get clusterissuer

# SecretProviderClass
kubectl get secretproviderclass -n banking

# Certificate (after gateway is applied)
kubectl get certificate -n banking
```

---

## CI/CD Pipeline

**File:** `.github/workflows/shared-infra.yaml`

### Triggers

| Trigger | Condition |
|---------|-----------|
| **Push** | `main` branch + changes in `shared/**` |
| **Manual** | `workflow_dispatch` button |

### Pipeline Steps

```yaml
1. Checkout code
2. Azure Login (service principal)
3. Set AKS Context
4. Substitute secrets in secret-providerclass.yaml (envsubst)
5. Deploy Namespace
6. Deploy Cluster Issuer
7. Deploy ConfigMap
8. Deploy Secret Provider Class
9. Deploy Gateway
10. Deploy HTTPRoutes
11. Verify Deployments
```

### Required GitHub Secrets

| Secret | Description | How to Get |
|--------|-------------|------------|
| `AZURE_CREDENTIALS` | Service principal JSON | `az ad sp create-for-rbac --sdk-auth` |
| `AZURE_RESOURCE_GROUP` | AKS resource group | Azure Portal |
| `AKS_CLUSTER_NAME` | AKS cluster name | Azure Portal |
| `AZURE_TENANT_ID` | Azure tenant ID | Azure Portal → Azure AD |
| `MANAGED_IDENTITY_CLIENT_ID` | Managed identity client ID | See below |
| `KEYVAULT_NAME` | Key Vault name | Azure Portal |

### Getting Managed Identity Client ID

```bash
# For AKS kubelet identity
az aks show \
  --resource-group <resource-group> \
  --name <aks-cluster-name> \
  --query "identityProfile.kubeletidentity.clientId" \
  -o tsv
```

---

## DNS Configuration

### Step 1: Get External IP

After deploying the Gateway:

```bash
kubectl get gateway app-gateway -n banking -o jsonpath='{.status.addresses[0].value}'
```

Or watch for it:
```bash
kubectl get gateway app-gateway -n banking --watch
```

### Step 2: Configure DNS

Go to your domain registrar and add an A record:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | `@` | `<EXTERNAL-IP>` | 300 |

### Step 3: Verify

```bash
# Check DNS propagation
nslookup kwasiboateng.lol

# Test HTTPS (after certificate is issued)
curl -I https://kwasiboateng.lol
```

---

## Azure Key Vault Setup

### Step 1: Create Key Vault

```bash
az keyvault create \
  --name <keyvault-name> \
  --resource-group <resource-group> \
  --location <location>
```

### Step 2: Add Secrets

```bash
# Database credentials
az keyvault secret set --vault-name <keyvault-name> --name db-username --value "<db-user>"
az keyvault secret set --vault-name <keyvault-name> --name db-password --value "<db-password>"

# JWT secret
az keyvault secret set --vault-name <keyvault-name> --name jwt-secret --value "<jwt-secret-key>"
```

### Step 3: Grant Access to Managed Identity

```bash
# Get managed identity object ID
IDENTITY_OBJECT_ID=$(az aks show \
  --resource-group <resource-group> \
  --name <aks-cluster-name> \
  --query "identityProfile.kubeletidentity.objectId" \
  -o tsv)

# Grant access policy
az keyvault set-policy \
  --name <keyvault-name> \
  --object-id $IDENTITY_OBJECT_ID \
  --secret-permissions get list
```

---

## Migration from Ingress-Nginx

If you're migrating from ingress-nginx to Gateway API:

### Why Migrate?

| Aspect | Ingress-Nginx | Gateway API |
|--------|---------------|-------------|
| **Status** | EOL March 2026 | Active, GA |
| **Standard** | Legacy Ingress API | Modern Gateway API |
| **Features** | Limited | Rich routing, policies |
| **Maintenance** | No new features | Actively developed |

### Migration Checklist

```
✅ Install Gateway API CRDs
✅ Install Envoy Gateway
✅ Update cert-manager with Gateway API support
✅ Create Gateway resource (replaces IngressClass)
✅ Create HTTPRoute resources (replaces Ingress)
✅ Update ClusterIssuer for Gateway API
✅ Update DNS to new LoadBalancer IP
✅ Remove old ingress-nginx installation
```

### Key Differences

| Ingress (Old) | Gateway API (New) |
|---------------|-------------------|
| `Ingress` resource | `Gateway` + `HTTPRoute` resources |
| `ingressClassName: nginx` | `gatewayClassName: envoy` |
| Annotations for config | Native API fields |
| Single resource | Separation of concerns |

### Remove Old Ingress-Nginx

```bash
# After migration is complete
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete namespace ingress-nginx
```

---

## Troubleshooting

### Gateway Not Getting External IP

```bash
# Check Gateway status
kubectl describe gateway app-gateway -n banking

# Check Envoy Gateway logs
kubectl logs -n envoy-gateway-system -l app.kubernetes.io/name=envoy-gateway

# Check if GatewayClass exists
kubectl get gatewayclass
```

### HTTPRoute Not Working

```bash
# Check HTTPRoute status
kubectl describe httproute backend-route -n banking
kubectl describe httproute frontend-route -n banking

# Verify services exist
kubectl get svc -n banking

# Check if routes are accepted
kubectl get httproute -n banking -o jsonpath='{.items[*].status.parents[*].conditions}'
```

### Certificate Not Issued

```bash
# Check certificate status
kubectl describe certificate app-tls-secret -n banking

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager

# Check certificate request
kubectl get certificaterequest -n banking

# Verify Gateway annotation
kubectl get gateway app-gateway -n banking -o yaml | grep cert-manager
```

### Secrets Not Loading

```bash
# Check SecretProviderClass
kubectl describe secretproviderclass azure-keyvault-secrets -n banking

# Check if Kubernetes secret was created
kubectl get secret app-secrets -n banking

# Check CSI driver pods
kubectl get pods -n kube-system | grep csi

# Test Key Vault access manually
az keyvault secret show --vault-name <keyvault-name> --name db-username
```

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `certificate not ready` | DNS not propagated | Wait for DNS, check with `nslookup` |
| `no matching parent` | Gateway not ready | Wait for Gateway External IP |
| `connection refused` | Service not running | Check pod status, logs |
| `403 Forbidden` | Key Vault access denied | Grant managed identity access |
| `secret not found` | CSI driver not mounted | Check volume mount in deployment |

---

## File Reference

| File | Kind | Namespace | Purpose |
|------|------|-----------|---------|
| `namespace.yaml` | Namespace | - | Create `banking` namespace |
| `gateway.yaml` | Gateway | banking | Entry point for traffic |
| `httproute.yaml` | HTTPRoute | banking | Traffic routing rules |
| `cluster-issuer.yaml` | ClusterIssuer | - | Let's Encrypt TLS issuer |
| `configmap.yaml` | ConfigMap | banking | App configuration |
| `secret-providerclass.yaml` | SecretProviderClass | banking | Key Vault integration |
| `install-prerequisites.sh` | Script | - | One-time cluster setup |

---

## Quick Commands

```bash
# View all resources in banking namespace
kubectl get all -n banking

# View Gateway status
kubectl get gateway -n banking

# View HTTPRoutes
kubectl get httproute -n banking

# View secrets
kubectl get secrets -n banking

# View configmaps
kubectl get configmaps -n banking

# View certificate status
kubectl get certificate -n banking

# View events (helpful for debugging)
kubectl get events -n banking --sort-by='.lastTimestamp'

# Get Gateway External IP
kubectl get gateway app-gateway -n banking -o jsonpath='{.status.addresses[0].value}'

# Delete and recreate all resources
kubectl delete -f shared/
kubectl apply -f shared/
```

---

**Maintained by:** Kwasi Boateng  
**Domain:** kwasiboateng.lol  
**Email:** boatengkwasi0303@gmail.com

---

## Changelog

### March 2026
- Migrated from ingress-nginx to Kubernetes Gateway API
- Replaced Ingress with Gateway + HTTPRoute resources
- Updated cert-manager to use Gateway API solver
- Added Envoy Gateway as the Gateway API implementation
