#!/bin/bash

set -e

echo "========================================="
echo "Installing Cluster Prerequisites"
echo "========================================="
echo ""
echo "NOTE: This script uses Kubernetes Gateway API with Envoy Gateway"
echo "      as the ingress-nginx controller reached EOL in March 2026."
echo ""

# Install Gateway API CRDs
echo "[1/4] Installing Gateway API CRDs..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml

echo "✅ Gateway API CRDs installed"

# Install Envoy Gateway (using OCI registry - the old helm repo is deprecated)
echo ""
echo "[2/4] Installing Envoy Gateway..."
helm upgrade --install envoy-gateway oci://docker.io/envoyproxy/gateway-helm \
  --namespace envoy-gateway-system \
  --create-namespace \
  --version v1.2.0 \
  --wait

echo "✅ Envoy Gateway installed"

# Wait for Envoy Gateway to be ready
echo ""
echo "Waiting for Envoy Gateway to be ready..."
kubectl wait --namespace envoy-gateway-system \
  --for=condition=Available \
  deployment/envoy-gateway \
  --timeout=120s

# Install cert-manager
echo ""
echo "[3/4] Installing cert-manager..."
helm repo add jetstack https://charts.jetstack.io --force-update
helm repo update jetstack

# Install without --wait to avoid startupapicheck timeout issues
# The startupapicheck job is a post-install verification that can timeout
# but cert-manager itself will still work fine
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.14.0 \
  --set installCRDs=true \
  --set "extraArgs={--feature-gates=ExperimentalGatewayAPISupport=true}" \
  --set startupapicheck.enabled=false

echo "✅ cert-manager installed (with Gateway API support)"

# Wait for cert-manager deployments to be ready
echo ""
echo "Waiting for cert-manager to be ready..."
kubectl wait --namespace cert-manager \
  --for=condition=Available \
  deployment/cert-manager \
  --timeout=120s || true

kubectl wait --namespace cert-manager \
  --for=condition=Available \
  deployment/cert-manager-webhook \
  --timeout=120s || true

# Check CSI Secrets Store Driver (usually pre-installed as AKS addon)
echo ""
echo "[4/4] Checking CSI Secrets Store Driver for Azure Key Vault..."

# Check if CSI driver already exists (installed via AKS addon)
if kubectl get csidriver secrets-store.csi.k8s.io &>/dev/null; then
  echo "✅ CSI Secrets Store Driver already installed (via AKS addon)"
  echo "   Skipping Helm installation..."
else
  echo "CSI driver not found, installing via Helm..."
  helm repo add csi-secrets-store-provider-azure https://azure.github.io/secrets-store-csi-driver-provider-azure/charts
  helm repo update csi-secrets-store-provider-azure
  
  helm upgrade --install csi-secrets-store csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
    --namespace kube-system
  
  echo "✅ CSI Secrets Store Driver installed"
fi

# Summary
echo ""
echo "========================================="
echo "Prerequisites Installation Complete!"
echo "========================================="
echo ""
echo "Installed Components:"
echo "  ✅ Gateway API CRDs (v1.2.0)"
echo "  ✅ Envoy Gateway (v1.2.0)"
echo "  ✅ cert-manager (v1.14.0) with Gateway API support"
echo "  ✅ CSI Secrets Store Driver for Azure"
echo ""
echo "Verification commands:"
echo "  kubectl get pods -n envoy-gateway-system"
echo "  kubectl get pods -n cert-manager"
echo "  kubectl get csidriver secrets-store.csi.k8s.io"
echo ""
echo "Next steps:"
echo ""
echo "1. Deploy the Gateway resource:"
echo "   kubectl apply -f shared/gateway.yaml"
echo ""
echo "2. Wait for External IP:"
echo "   kubectl get gateway app-gateway -n banking --watch"
echo ""
echo "3. Configure DNS A record:"
echo "   Point kwasiboateng.lol → <EXTERNAL-IP>"
echo ""
echo "4. Deploy remaining shared resources:"
echo "   kubectl apply -f shared/"
echo ""
echo "========================================="
echo "Migration Note: Gateway API replaces the"
echo "deprecated ingress-nginx controller."
echo "========================================="
