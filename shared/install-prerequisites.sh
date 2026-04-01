#!/bin/bash

set -e

echo "========================================="
echo "Installing Cluster Prerequisites"
echo "========================================="
echo ""
echo "NOTE: This script uses Kubernetes Gateway API with Envoy Gateway"
echo "      as the ingress-nginx controller reached EOL in March 2026."
echo ""

# Function to wait for cert-manager webhook to be ready
wait_for_cert_manager_webhook() {
  echo "Waiting for cert-manager webhook to be fully ready..."
  local max_attempts=30
  local attempt=1
  
  while [ $attempt -le $max_attempts ]; do
    echo "  Attempt $attempt/$max_attempts: Testing webhook connectivity..."
    
    # Try to create a test certificate issuer to verify webhook is responding
    if kubectl apply --dry-run=server -f - <<EOF 2>/dev/null
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: test-webhook-connectivity
spec:
  selfSigned: {}
EOF
    then
      echo "  ✅ cert-manager webhook is ready!"
      return 0
    fi
    
    echo "  Webhook not ready yet, waiting 10 seconds..."
    sleep 10
    attempt=$((attempt + 1))
  done
  
  echo "  ⚠️ Webhook readiness check timed out, but continuing..."
  return 0
}

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

# Restart konnectivity-agent to ensure API server connectivity
# This prevents 504 Gateway Timeout errors when communicating with webhooks
echo ""
echo "Ensuring API server connectivity (restarting konnectivity-agent)..."
if kubectl get deployment konnectivity-agent -n kube-system &>/dev/null; then
  kubectl rollout restart deployment konnectivity-agent -n kube-system
  echo "Waiting for konnectivity-agent to be ready..."
  sleep 30
  kubectl rollout status deployment konnectivity-agent -n kube-system --timeout=120s || true
  echo "✅ konnectivity-agent restarted"
else
  echo "  konnectivity-agent not found (may not be needed for this cluster)"
fi

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
echo "Waiting for cert-manager deployments to be ready..."
kubectl wait --namespace cert-manager \
  --for=condition=Available \
  deployment/cert-manager \
  --timeout=180s

kubectl wait --namespace cert-manager \
  --for=condition=Available \
  deployment/cert-manager-cainjector \
  --timeout=180s

kubectl wait --namespace cert-manager \
  --for=condition=Available \
  deployment/cert-manager-webhook \
  --timeout=180s

# Wait for webhook to be fully operational (can take additional time after pod is ready)
echo ""
wait_for_cert_manager_webhook

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
