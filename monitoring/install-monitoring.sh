#!/bin/bash
set -e

# -------------------------------
# Variables
# -------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="monitoring"
RELEASE_NAME="kube-prom-stack"
HELM_REPO="https://prometheus-community.github.io/helm-charts"
CHART_NAME="kube-prometheus-stack"
ALERTMANAGER_CONFIG="$SCRIPT_DIR/alertmanager-config.yaml"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-SecureGrafana123!}" # export GRAFANA_PASSWORD as env before running


# -------------------------------
# 1️⃣ Create Namespace
# -------------------------------
echo "Creating namespace '$NAMESPACE'..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
echo "✅ Namespace '$NAMESPACE' ready"

# -------------------------------
# 2️⃣ Add Helm Repo
# -------------------------------
echo ""
echo "Adding Helm repository..."
helm repo add prometheus-community $HELM_REPO
helm repo update
echo "✅ Helm repository updated"

# -------------------------------
# 3️⃣ Install / Upgrade kube-prometheus-stack
# -------------------------------
echo ""
echo "Installing kube-prometheus-stack (this may take a few minutes)..."
helm upgrade --install $RELEASE_NAME prometheus-community/$CHART_NAME \
  --namespace $NAMESPACE \
  --wait \
  --timeout 10m \
  --values - <<EOF
grafana:
  adminUser: admin
  adminPassword: $GRAFANA_PASSWORD
  service:
    type: ClusterIP
  sidecar:
    dashboards:
      enabled: true
      label: grafana_dashboard
prometheus:
  prometheusSpec:
    retention: 10d
alertmanager:
  alertmanagerSpec:
    replicas: 1
kubeStateMetrics:
  enabled: true
nodeExporter:
  enabled: true
EOF

echo "✅ kube-prometheus-stack installed successfully in '$NAMESPACE'"

# -------------------------------
# 4️⃣ Apply Alertmanager Config (Secret)
# -------------------------------
if [ -f "$ALERTMANAGER_CONFIG" ]; then
  echo ""
  
  # Check if SLACK_WEBHOOK_URL is set
  if [ -z "$SLACK_WEBHOOK_URL" ]; then
    echo "⚠️  WARNING: SLACK_WEBHOOK_URL is not set. Slack notifications will not work."
    echo "   Set it with: export SLACK_WEBHOOK_URL=\"https://hooks.slack.com/services/...\""
  fi
  
  echo "Applying Alertmanager configuration (Secret)..."
  
  # Use envsubst to replace ${SLACK_WEBHOOK_URL} with actual value
  envsubst < "$ALERTMANAGER_CONFIG" | kubectl apply -f -
  echo "✅ Applied Alertmanager Secret with substituted values"

  # Restart Alertmanager to pick up the new config (delete pod, StatefulSet recreates it)
  echo "🔄 Restarting Alertmanager pods..."
  kubectl -n $NAMESPACE delete pod -l app.kubernetes.io/name=alertmanager --ignore-not-found=true
  echo "✅ Alertmanager restarted to apply new configuration"
else
  echo "⚠️  Alertmanager config not found at $ALERTMANAGER_CONFIG - skipping"
fi

# -------------------------------
# 5️⃣ Summary
# -------------------------------
echo ""
echo "========================================="
echo "🎉 Monitoring Stack Installation Complete!"
echo "========================================="
echo ""
echo "Grafana Credentials:"
echo "  Username: admin"
echo "  Password: $GRAFANA_PASSWORD"
echo ""
echo "Access Grafana:"
echo "  kubectl port-forward svc/${RELEASE_NAME}-grafana 3000:80 -n $NAMESPACE"
echo "  Then open: http://localhost:3000"
echo ""
echo "Access Prometheus:"
echo "  kubectl port-forward svc/${RELEASE_NAME}-kube-prometheus-prometheus 9090:9090 -n $NAMESPACE"
echo "  Then open: http://localhost:9090"
echo ""
