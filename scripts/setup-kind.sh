#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# KIND Cluster Bootstrap Script
#
# Usage: ./scripts/setup-kind.sh [single|multi]
#   single: Single-node cluster (default)
#   multi:  Multi-node cluster (1 control-plane + 2 workers)
# ---------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CLUSTER_NAME="devops-cluster"
CONFIG_TYPE="${1:-single}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# ---------------------------------------------------------------------------
# Prerequisites Check
# ---------------------------------------------------------------------------

check_prerequisite() {
    local cmd="$1"
    local install_url="$2"
    if ! command -v "$cmd" &> /dev/null; then
        error "$cmd is not installed."
        echo "Install from: $install_url"
        exit 1
    fi
    info "$cmd: $(command -v "$cmd")"
}

info "Checking prerequisites..."
check_prerequisite docker "https://docs.docker.com/get-docker/"
check_prerequisite kubectl "https://kubernetes.io/docs/tasks/tools/"
check_prerequisite kind "https://kind.sigs.k8s.io/docs/user/quick-start/"

# ---------------------------------------------------------------------------
# Select Configuration
# ---------------------------------------------------------------------------

if [[ "$CONFIG_TYPE" == "multi" ]]; then
    CONFIG_FILE="${PROJECT_ROOT}/kind/multi-node.yaml"
    info "Using multi-node configuration (1 control-plane + 2 workers)"
else
    CONFIG_FILE="${PROJECT_ROOT}/kind/single-node.yaml"
    info "Using single-node configuration (1 control-plane)"
fi

# ---------------------------------------------------------------------------
# Delete Existing Cluster (if any)
# ---------------------------------------------------------------------------

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    warn "Cluster '${CLUSTER_NAME}' already exists. Deleting..."
    kind delete cluster --name "$CLUSTER_NAME"
fi

# ---------------------------------------------------------------------------
# Create Cluster
# ---------------------------------------------------------------------------

info "Creating KIND cluster '${CLUSTER_NAME}'..."
kind create cluster --name "$CLUSTER_NAME" --config "$CONFIG_FILE"

# ---------------------------------------------------------------------------
# Verify Cluster
# ---------------------------------------------------------------------------

info "Verifying cluster..."
kubectl cluster-info
kubectl get nodes -o wide

# ---------------------------------------------------------------------------
# Install NGINX Ingress Controller
# ---------------------------------------------------------------------------

info "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

info "Waiting for Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=180s

# ---------------------------------------------------------------------------
# Display Summary
# ---------------------------------------------------------------------------

echo ""
echo "=========================================="
echo -e "${GREEN}KIND Cluster Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "Cluster Name: ${CLUSTERNAME}"
echo "Config File:  ${CONFIG_FILE}"
echo "Context:      kind-${CLUSTER_NAME}"
echo ""
echo "Status:"
kubectl get nodes
kubectl get pods -n ingress-nginx

echo ""
echo "Useful commands:"
echo "  - kubectl get pods -A"
echo "  - kubectl get svc -A"
echo "  - kubectl get ingress -A"
echo "  - kind load docker-image <image> --name ${CLUSTER_NAME}"
echo ""
