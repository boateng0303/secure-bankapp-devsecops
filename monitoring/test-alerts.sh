#!/bin/bash

# ============================================
# Test Alerts Script
# Triggers demo alerts in the banking namespace
# For testing Prometheus alerts and Slack notifications
# ============================================

set -e

NAMESPACE="banking"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "========================================="
echo "🧪 Alert Testing Script"
echo "========================================="
echo ""

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo -e "${RED}❌ Namespace '$NAMESPACE' does not exist.${NC}"
    echo "   Run the shared-infra pipeline first to create it."
    exit 1
fi

# Function to show menu
show_menu() {
    echo "Select which alert to trigger:"
    echo ""
    echo "  1) PodCrashLooping  - Pod that crashes repeatedly"
    echo "  2) HighPodCPU       - Pod with high CPU usage"
    echo "  3) All alerts       - Trigger both alerts"
    echo "  4) Cleanup          - Remove all test pods"
    echo "  5) Exit"
    echo ""
    read -p "Enter choice [1-5]: " choice
}

# Trigger CrashLoop alert
trigger_crashloop() {
    echo ""
    echo -e "${YELLOW}🔄 Creating crashing pod...${NC}"
    kubectl run crash-test \
        --image=busybox \
        --namespace=$NAMESPACE \
        --restart=Always \
        --labels="app=crash-test,test=true" \
        -- /bin/sh -c "echo 'Starting...' && sleep 5 && echo 'Crashing!' && exit 1" \
        2>/dev/null || echo "Pod already exists"
    
    echo -e "${GREEN}✅ crash-test pod created${NC}"
    echo ""
    echo "📊 Alert: PodCrashLooping"
    echo "⏱️  Expected fire time: ~3-5 minutes (needs >2 restarts)"
    echo ""
}

# Trigger High CPU alert
trigger_high_cpu() {
    echo ""
    echo -e "${YELLOW}🔥 Creating CPU stress pod...${NC}"
    kubectl run cpu-stress \
        --image=progrium/stress \
        --namespace=$NAMESPACE \
        --restart=Never \
        --labels="app=cpu-stress,test=true" \
        -- --cpu 2 --timeout 600s \
        2>/dev/null || echo "Pod already exists"
    
    echo -e "${GREEN}✅ cpu-stress pod created${NC}"
    echo ""
    echo "📊 Alert: HighPodCPU"
    echo "⏱️  Expected fire time: ~2-3 minutes"
    echo ""
}

# Cleanup test pods
cleanup() {
    echo ""
    echo -e "${YELLOW}🧹 Cleaning up test pods...${NC}"
    kubectl delete pod crash-test cpu-stress -n $NAMESPACE --ignore-not-found=true
    echo -e "${GREEN}✅ Test pods removed${NC}"
    echo ""
}

# Show status
show_status() {
    echo ""
    echo "📋 Current test pods in $NAMESPACE:"
    kubectl get pods -n $NAMESPACE -l test=true 2>/dev/null || echo "   No test pods found"
    echo ""
}

# Main menu loop
while true; do
    show_menu
    
    case $choice in
        1)
            trigger_crashloop
            show_status
            ;;
        2)
            trigger_high_cpu
            show_status
            ;;
        3)
            trigger_crashloop
            trigger_high_cpu
            show_status
            echo "========================================="
            echo "🎯 Both test pods created!"
            echo ""
            echo "👀 Watch for alerts:"
            echo "   - Check Slack #alerts channel"
            echo "   - Or port-forward Prometheus: kubectl port-forward svc/kube-prom-stack-kube-prometheus-prometheus 9090:9090 -n monitoring"
            echo "   - Then open: http://localhost:9090/alerts"
            echo "========================================="
            ;;
        4)
            cleanup
            ;;
        5)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            ;;
    esac
done
