# GitOps with ArgoCD on KIND

## Overview

ArgoCD is installed in the local KIND cluster and continuously watches the GitHub repository for changes to the `kubernetes/` folder. When changes are detected, it automatically syncs them to the cluster.

## Architecture

```
GitHub (main branch)
    │
    │ ArgoCD polls every 3 minutes
    ▼
ArgoCD Application Controller (in KIND)
    │
    │ GitOps Sync
    ▼
KIND Cluster: devops-app namespace
    ├── Deployment
    ├── Service
    ├── Ingress
    ├── ConfigMap
    └── Secret

> **Note**: HorizontalPodAutoscaler (HPA) was removed from the manifests. ArgoCD now fully manages the Deployment replica count.
```

## Installation

```bash
# Install ArgoCD (server-side apply for CRD compatibility)
./argocd/install.sh
```

This will:
1. Create `argocd` namespace
2. Install ArgoCD components
3. Patch ArgoCD server to NodePort
4. Apply the Application manifest

## ArgoCD Application Configuration

**File**: `argocd/application.yaml`

Key settings:
- **Repo**: `https://github.com/Ramiz-Takildar/devops-portfolio-platform.git`
- **Path**: `kubernetes/` (only K8s manifests)
- **TargetRevision**: `main`
- **Destination**: `devops-app` namespace
- **SyncPolicy**: Auto-sync with prune, self-heal, retry backoff
- **ignoreDifferences**: Ignores the server-managed `deployment.kubernetes.io/revision` annotation so ArgoCD shows the Deployment as **Synced** instead of **OutOfSync**

## Access ArgoCD UI

```bash
# Get admin password
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d

# Port-forward UI
kubectl port-forward svc/argocd-server -n argocd 8443:443
```

Open: **https://localhost:8443**
- Username: `admin`
- Password: (output from command above)

## How GitOps Flow Works

### Flow Diagram

```
Developer pushes to main
        │
        ▼
GitHub Actions CI (lint + test)
        │
        ▼
GitHub Actions CD (build image → push to GHCR)
        │
        ▼
ArgoCD detects new commit (polls GitHub every 3 min)
        │
        ▼
ArgoCD compares cluster state vs. GitHub state
        │
        ▼
ArgoCD auto-syncs: applies new manifests
        │
        ▼
KIND cluster updated with new image/config
```

### What Happens on Every Push

1. **CI Workflow** runs (same as before): lint, test, Trivy scan
2. **CD Workflow** runs: builds multi-arch image, scans with Trivy, pushes to GHCR
3. **ArgoCD** (running inside KIND) detects the new commit on `main`
4. **ArgoCD Application Controller** compares the desired state (Git) vs. live state (KIND)
5. **Auto-sync** applies changes automatically with:
   - `Prune`: removes resources deleted from Git
   - `SelfHeal`: reverts manual changes in the cluster back to Git state
   - `Retry`: retries failed syncs with exponential backoff (5s → 10s → 20s → 40s)

## Manual Sync

If auto-sync is disabled, you can trigger sync manually:

```bash
# Via CLI
argocd app sync devops-portfolio

# Via UI
kubectl port-forward svc/argocd-server -n argocd 8443:443
# Open https://localhost:8443 → Applications → devops-portfolio → Sync
```

## Current Status

```bash
# Check sync status
kubectl get application devops-portfolio -n argocd -o wide

# Check what ArgoCD sees
kubectl get application devops-portfolio -n argocd -o jsonpath='{.status.sync.status}'

# Check resource health
kubectl get application devops-portfolio -n argocd -o jsonpath='{.status.health.status}'
```

## Troubleshooting

### Application shows OutOfSync

If the application shows OutOfSync, check the diff in the ArgoCD UI to identify the exact field.

Common causes:
1. **Deployment revision annotation** — already handled by `ignoreDifferences` in `argocd/application.yaml`.
2. **Ingress shows Progressing** — expected in KIND without an Ingress Controller. The Ingress resource works fine for routing but ArgoCD sees an empty `status.loadBalancer` and marks it Progressing. Install the NGINX Ingress Controller to resolve:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
   kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
   ```

```bash
# Force a sync
argocd app sync devops-portfolio --prune --force

# Or via UI: click "Sync" → check "Prune" + "Force" → click "Synchronize"
```

### Can't access ArgoCD UI

```bash
# Verify ArgoCD server pod is running
kubectl get pods -n argocd

# Restart port-forward
kubectl port-forward svc/argocd-server -n argocd 8443:443

# Or use NodePort directly (requires extra KIND port mapping)
curl -k https://localhost:30443
```

### Forgot admin password

```bash
# Reset it
kubectl patch secret argocd-secret -n argocd -p '{"stringData": {"admin.password": "'$2a$10$...'", "admin.passwordMtime": "'$(date +%FT%T%Z)'"}}'
```

## Production Considerations

- **Private repos**: Add a Kubernetes Secret with a GitHub PAT or deploy key, then configure it in the ArgoCD Application spec
- **Apps of Apps**: Use an ArgoCD `AppProject` + root Application to manage multiple apps
- **Notifications**: Install ArgoCD Notifications for Slack/Teams alerts on sync failures
- **Rollback**: ArgoCD keeps sync history — rollback to any previous revision from the UI
