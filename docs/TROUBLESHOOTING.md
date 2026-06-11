# Troubleshooting Guide

## Application Issues

### pytest fails to collect tests

**Symptom**: `Pytest: No tests collected`

**Cause**: Missing `__init__.py` in tests directory or import errors.

**Fix**:
```bash
cd app
touch tests/__init__.py
python -m pytest tests/ -v
```

### Application fails to start locally

**Symptom**: `ModuleNotFoundError: No module named 'flask'`

**Cause**: Dependencies not installed.

**Fix**:
```bash
cd app
pip install -r requirements.txt
python main.py
```

## Docker Issues

### Port 5000 already in use (macOS)

**Symptom**: `ports are not available: exposing port TCP 0.0.0.0:5000 -> ...: listen tcp 0.0.0.0:5000: bind: address already in use`

**Cause**: macOS Control Center (AirDrop/Handoff) uses port 5000.

**Fix**:
```bash
# Use a different host port
docker run -d -p 8888:5000 devops-app:local
```

### Docker image is too large

**Symptom**: Image size > 150MB

**Cause**: Using full `python:3.12` image or including unnecessary packages.

**Fix**:
- Use `python:3.12-alpine` as base image
- Use multi-stage build
- Remove curl if you can use Python stdlib for HEALTHCHECK
- Review `.dockerignore` to exclude unnecessary files

```bash
# Rebuild with optimizations
docker build -t devops-app:local .
docker images devops-app:local
```

## KIND Cluster Issues

### Cluster creation fails

**Symptom**: `failed to create cluster: docker run error`

**Cause**: Docker daemon not running or insufficient resources.

**Fix**:
```bash
# Check Docker is running
docker info

# Ensure sufficient resources (Docker Desktop → Settings → Resources)
# - CPUs: 4+
# - Memory: 8GB+
# - Disk: 20GB+

# Delete existing cluster and retry
kind delete cluster --name devops-cluster
kind create cluster --config kind/single-node.yaml
```

### kubectl cannot connect to cluster

**Symptom**: `The connection to the server localhost:8080 was refused`

**Cause**: kubectl context is not set to the KIND cluster.

**Fix**:
```bash
# List available contexts
kubectl config get-contexts

# Switch to KIND context
kubectl config use-context kind-devops-cluster

# Verify
kubectl cluster-info
```

## Kubernetes Deployment Issues

### ImagePullBackOff

**Symptom**: Pods stuck in `ImagePullBackOff` status.

**Cause**: The image referenced in the Deployment doesn't exist or isn't accessible from the cluster.

**Fix - Option 1: Load local image**:
```bash
docker build -t devops-app:local .
kind load docker-image devops-app:local --name devops-cluster
kubectl set image deployment/devops-app app=devops-app:local -n devops-app
```

**Fix - Option 2: Update imagePullPolicy**:
```bash
# Change imagePullPolicy to IfNotPresent (already set in deployment.yaml)
# If using a private registry, create an imagePullSecret
kubectl create secret docker-registry ghcr-pull-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_TOKEN \
  -n devops-app
```

### Pods stuck in Pending

**Symptom**: Pods remain in `Pending` status.

**Cause**: Insufficient cluster resources or missing nodes.

**Fix**:
```bash
# Check node status
kubectl get nodes

# Check pod events
kubectl describe pod -n devops-app <pod-name>

# Check resource requests
kubectl get events -n devops-app
```

### CrashLoopBackOff

**Symptom**: Pods repeatedly crash and restart.

**Cause**: Application errors, missing environment variables, or resource limits too low.

**Fix**:
```bash
# Check pod logs
kubectl logs -n devops-app <pod-name> --previous

# Check pod events
kubectl describe pod -n devops-app <pod-name>

# Check if liveness probe is too aggressive
# Adjust initialDelaySeconds or periodSeconds in deployment.yaml
```
## Monitoring Issues

### Prometheus targets show DOWN

**Symptom**: Prometheus UI shows targets as DOWN.

**Cause**: Pods don't have prometheus.io annotations or ServiceMonitor CRD is missing.

**Fix**:
```bash
# Check pod annotations
kubectl get pods -n devops-app -o yaml | grep -A 5 annotations

# Verify prometheus.io/scrape: "true" is set
# Already in deployment.yaml: metadata.annotations.prometheus.io/scrape

# For ServiceMonitor, install Prometheus Operator CRDs
kubectl apply -f https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.74.0/bundle.yaml
```

### Grafana dashboards not loading

**Symptom**: Grafana shows "No dashboards" or provisioned dashboards don't appear.

**Cause**: ConfigMap not mounted or provisioning config incorrect.

**Fix**:
```bash
# Check ConfigMap exists
kubectl get configmap -n monitoring grafana-dashboards

# Check Grafana pod logs
kubectl logs -n monitoring <grafana-pod>

# Restart Grafana to pick up changes
kubectl rollout restart deployment/grafana -n monitoring
```

### ServiceMonitor not recognized

**Symptom**: `error: no matches for kind "ServiceMonitor" in version "monitoring.coreos.com/v1"`

**Cause**: Prometheus Operator CRDs are not installed.

**Fix**:
```bash
# Install Prometheus Operator
kubectl apply -f https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.74.0/bundle.yaml

# Re-apply ServiceMonitor
kubectl apply -f monitoring/servicemonitor.yaml
```

## CI/CD Issues

### GitHub Actions workflow fails on Trivy scan

**Symptom**: Trivy scan exits with code 1.

**Cause**: CRITICAL vulnerabilities found.

**Fix**:
```bash
# Run Trivy locally to identify issues
trivy image --severity CRITICAL devops-app:local

# Update base image or dependencies
# Rebuild and push
```

### Docker build fails on GitHub Actions

**Symptom**: `Error: buildx failed with: error: failed to solve`

**Cause**: Invalid Dockerfile syntax or missing context files.

**Fix**:
```bash
# Validate Dockerfile locally
docker build -t devops-app:local .

# Check .dockerignore isn't excluding required files
```

## General Tips

### Reset everything and start fresh

```bash
# Stop and remove containers
docker stop devops-app || true
docker rm devops-app || true

# Delete KIND cluster
kind delete cluster --name devops-cluster

# Clean up Docker images
docker rmi devops-app:local || true

# Rebuild and redeploy
make build
./scripts/setup-kind.sh
kubectl apply -f kubernetes/
kubectl apply -f monitoring/
```

### Check all resources

```bash
# Application namespace
kubectl get all -n devops-app

# Monitoring namespace
kubectl get all -n monitoring

# All namespaces
kubectl get all --all-namespaces
```

### Get detailed resource information

```bash
# Describe a pod
kubectl describe pod -n devops-app <pod-name>

# View pod logs
kubectl logs -n devops-app <pod-name> -f

# View logs for all pods in deployment
kubectl logs -n devops-app -l app.kubernetes.io/name=devops-portfolio-app -f
```
