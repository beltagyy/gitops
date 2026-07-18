#!/usr/bin/env bash
# Quick-start local Kind cluster for GitOps development
# Usage: ./kind-setup.sh [start|stop|status|deploy]

set -euo pipefail

CLUSTER_NAME="gitops-local"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

check_deps() {
    local missing=()
    for cmd in kind kubectl docker; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing dependencies: ${missing[*]}"
    fi
    info "All dependencies found"
}

cluster_exists() {
    kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"
}

start() {
    check_deps

    if cluster_exists; then
        warn "Cluster '${CLUSTER_NAME}' already exists"
        kubectl cluster-info --context "kind-${CLUSTER_NAME}" 2>/dev/null && return 0
    fi

    info "Creating Kind cluster..."

    cat <<EOF | kind create cluster --name "$CLUSTER_NAME" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
      - containerPort: 30000
        hostPort: 30000
        protocol: TCP
EOF

    info "Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready node --all --timeout=120s

    install_components
    info "Cluster ready! Run: kubectl get nodes"
}

install_components() {
    info "Installing core components..."

    # Metrics server (for kubectl top)
    info "Installing metrics-server..."
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml 2>/dev/null || warn "metrics-server skipped"

    # NGINX Ingress Controller
    info "Installing NGINX Ingress..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml 2>/dev/null || warn "ingress-nginx skipped"

    info "Core components installed"
}

stop() {
    if ! cluster_exists; then
        warn "Cluster '${CLUSTER_NAME}' does not exist"
        return 0
    fi
    info "Deleting cluster '${CLUSTER_NAME}'..."
    kind delete cluster --name "$CLUSTER_NAME"
    info "Cluster deleted"
}

status() {
    if ! cluster_exists; then
        warn "Cluster '${CLUSTER_NAME}' does not exist. Run: $0 start"
        return 1
    fi

    echo ""
    info "Cluster: ${CLUSTER_NAME}"
    kubectl cluster-info --context "kind-${CLUSTER_NAME}"
    echo ""
    info "Nodes:"
    kubectl get nodes -o wide
    echo ""
    info "All pods:"
    kubectl get pods -A
    echo ""
    info "Services:"
    kubectl get svc -A
}

deploy() {
    if ! cluster_exists; then
        error "Cluster does not exist. Run: $0 start"
    fi
    info "Deploying apps from ${REPO_ROOT}/apps/..."
    kubectl apply -R -f "${REPO_ROOT}/apps/"
    info "Deployed. Check: kubectl get pods"
}

usage() {
    echo "Usage: $0 {start|stop|status|deploy}"
    echo ""
    echo "Commands:"
    echo "  start   - Create cluster and install components"
    echo "  stop    - Delete cluster"
    echo "  status  - Show cluster status"
    echo "  deploy  - Deploy apps from apps/ directory"
    echo ""
    echo "Examples:"
    echo "  $0 start       # Full setup from scratch"
    echo "  $0 deploy      # Deploy all apps"
    echo "  $0 status      # Check what's running"
    echo "  $0 stop        # Clean up"
}

case "${1:-help}" in
    start)  start ;;
    stop)   stop ;;
    status) status ;;
    deploy) deploy ;;
    *)      usage ;;
esac
