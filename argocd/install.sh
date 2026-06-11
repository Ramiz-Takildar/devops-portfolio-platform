#!/usr/bin/env bash
# Install ArgoCD into the local KIND cluster
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[INFO] Creating argocd namespace..."
kubectl apply -f "${SCRIPT_DIR}/namespace.yaml"

echo "[INFO] Installing ArgoCD (server-side apply for CRD compatibility)..."
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "[INFO] Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo "[INFO] Patching ArgoCD server to use NodePort (for local access)..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"name": "https", "port": 443, "targetPort": 8080, "nodePort": 30443}]}}'

echo "[INFO] Applying ArgoCD Application (GitOps watch)..."
kubectl apply -f "${SCRIPT_DIR}/application.yaml"

echo "[INFO] ArgoCD installed successfully!"
echo ""
echo "Get admin password (base64 encoded):"
echo "  kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "Port-forward for UI access:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8443:443"
echo "  Open: https://localhost:8443"
