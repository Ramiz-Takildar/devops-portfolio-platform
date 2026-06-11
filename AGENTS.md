# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Overview

This is a **production-grade DevOps portfolio platform** demonstrating enterprise-level DevOps, SRE, and Platform Engineering practices. The project showcases a complete end-to-end CI/CD pipeline with a Python Flask application deployed on a local KIND (Kubernetes in Docker) cluster.

**Core Purpose**: Demonstrate real-world DevOps skills including containerization, Kubernetes orchestration, GitOps, observability, and security scanning—all running locally for portfolio and learning purposes.

### Technology Stack

- **Application**: Python 3.12 + Flask + Gunicorn
- **Containerization**: Docker (multi-stage builds, Alpine-based)
- **Orchestration**: Kubernetes via KIND (local cluster)
- **CI/CD**: GitHub Actions (lint, test, build, scan, publish)
- **Registry**: GitHub Container Registry (GHCR)
- **Monitoring**: Prometheus + Grafana
- **Security**: Trivy vulnerability scanning
- **GitOps**: ArgoCD (optional deployment automation)

### Architecture Pattern

```
Developer → Git → GitHub Actions → Docker Build → GHCR → ArgoCD → KIND Cluster → Prometheus → Grafana
```

**GitOps Flow (with ArgoCD)**:
- Developer commits code changes to Git
- GitHub Actions CI/CD pipeline builds and pushes image to GHCR
- ArgoCD monitors Git repository for manifest changes
- ArgoCD automatically syncs changes to KIND cluster
- Prometheus scrapes metrics from deployed application
- Grafana visualizes metrics and provides dashboards

The application follows a **12-factor app** methodology with structured JSON logging, environment-based configuration, and health check endpoints suitable for Kubernetes probes.

## Repository Structure

```
devops-portfolio-platform/
├── app/                          # Flask application source
│   ├── main.py                   # Application with 5 endpoints
│   ├── requirements.txt          # Python dependencies
│   └── tests/                    # pytest unit tests (14 tests)
│       ├── __init__.py
│       └── test_app.py
├── kubernetes/                   # Kubernetes manifests
│   ├── namespace.yaml            # devops-app namespace
│   ├── configmap.yaml            # Non-sensitive configuration
│   ├── secret.yaml               # Sensitive data (demo values)
│   ├── deployment.yaml           # App deployment (2 replicas)
│   ├── service.yaml              # ClusterIP service
│   └── ingress.yaml              # NGINX ingress routing
├── monitoring/                   # Observability stack
│   ├── namespace.yaml            # monitoring namespace
│   ├── prometheus-rbac.yaml      # RBAC for Prometheus
│   ├── prometheus-config.yaml    # Scrape configuration
│   ├── prometheus-deployment.yaml # Prometheus server
│   ├── grafana-deployment.yaml   # Grafana server
│   ├── grafana-dashboard-provider.yaml
│   ├── grafana-dashboards-configmap.yaml
│   ├── servicemonitor.yaml       # ServiceMonitor for app
│   ├── alert-rules.yaml          # Alerting rules
│   └── dashboards/               # Grafana dashboard JSON
│       ├── infrastructure.json
│       └── application.json
├── kind/                         # KIND cluster configurations
│   ├── single-node.yaml          # 1 control-plane cluster
│   └── multi-node.yaml           # 1 control-plane + 2 workers
├── scripts/                      # Helper scripts
│   └── setup-kind.sh             # Cluster bootstrap script
├── docs/                         # Documentation
│   ├── ARCHITECTURE.md           # System design decisions
│   ├── KIND_SETUP.md             # KIND installation guide
│   ├── CI_CD_GUIDE.md            # Pipeline documentation
│   └── TROUBLESHOOTING.md        # Common issues
├── tests/                        # Integration & e2e tests
├── argocd/                       # ArgoCD GitOps (optional)
│   ├── namespace.yaml
│   ├── application.yaml
│   └── install.sh
├── .github/workflows/            # GitHub Actions pipelines
│   ├── ci.yml                    # Lint, test, security scan
│   └── cd.yml                    # Build, scan, push to GHCR
├── Dockerfile                    # Multi-stage Dockerfile
├── .dockerignore                 # Docker build exclusions
├── Makefile                      # Common development commands
├── README.md                     # Project documentation
└── AGENTS.md                     # This file
```

## Quick Start: One-Click Installation

For the fastest setup experience, use the automated installation script:

```bash
# Clone the repository
git clone https://github.com/Ramiz-Takildar/devops-portfolio-platform.git
cd devops-portfolio-platform

# Run one-click installation
chmod +x install.sh
./install.sh
```

**Installation Options**:
- `./install.sh` - Full installation (recommended)
- `./install.sh --skip-prereqs` - Skip prerequisite checks
- `./install.sh --multi-node` - Create multi-node cluster
- `./install.sh --no-monitoring` - Skip monitoring stack
- `./install.sh --argocd` - Install ArgoCD for GitOps automation
- `./install.sh --help` - Show all options

The script will automatically:
1. ✅ Check and install prerequisites (Docker, kubectl, KIND, Python)
2. ✅ Install Python dependencies
3. ✅ Run unit tests
4. ✅ Build Docker image
5. ✅ Create KIND cluster
6. ✅ Install NGINX Ingress Controller
7. ✅ Deploy application
8. ✅ Deploy monitoring stack (Prometheus & Grafana)
9. ✅ Verify all components

**Estimated Time**: 5-10 minutes (depending on internet speed and system resources)

After installation completes, you'll see access commands for:
- Application endpoints
- Grafana dashboards
- Prometheus metrics
- Application logs

---

## Step-by-Step Implementation Guide

For manual installation or to understand each step in detail, follow this guide:

### Phase 1: Prerequisites Setup

**Required Tools**:
- Docker 24.0+ (with 4+ CPU, 8GB+ RAM)
- kubectl 1.30+
- KIND 0.23+
- Python 3.12+ (for local development)
- Git

**Installation Commands**:

```bash
# macOS
brew install docker kubectl kind python@3.12

# Linux (Ubuntu/Debian)
# Docker: https://docs.docker.com/engine/install/
# kubectl:
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# KIND:
curl -Lo kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
chmod +x kind && sudo mv kind /usr/local/bin/
```

**Validation**:
```bash
docker --version          # Should show 24.0+
kubectl version --client  # Should show 1.30+
kind version              # Should show 0.23+
python3 --version         # Should show 3.12+
```

### Phase 2: Local Application Development

**Objective**: Run and test the Flask application locally before containerization.

**Steps**:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Ramiz-Takildar/devops-portfolio-platform.git
   cd devops-portfolio-platform
   ```

2. **Install Python dependencies**:
   ```bash
   cd app
   pip install -r requirements.txt
   ```

3. **Run unit tests**:
   ```bash
   python -m pytest tests/ -v
   ```
   **Expected**: 14 tests pass

4. **Run application locally**:
   ```bash
   python main.py
   ```
   **Expected**: Server starts on http://localhost:5000

5. **Verify endpoints**:
   ```bash
   curl http://localhost:5000/health
   curl http://localhost:5000/ready
   curl http://localhost:5000/metrics
   curl http://localhost:5000/version
   ```

**Success Criteria**:
- ✅ All 14 tests pass
- ✅ Application starts without errors
- ✅ All endpoints return 200 status
- ✅ Metrics endpoint shows Prometheus format

### Phase 3: Docker Containerization

**Objective**: Build and run the application in a Docker container.

**Steps**:

1. **Build Docker image**:
   ```bash
   cd ..  # Back to project root
   docker build -t devops-portfolio-app:local .
   ```
   **Expected**: Image builds successfully (~142MB)

2. **Verify image size**:
   ```bash
   docker images devops-portfolio-app:local --format "{{.Size}}"
   ```
   **Expected**: ~142MB (Alpine-based multi-stage build)

3. **Run container**:
   ```bash
   docker run -d --name devops-app -p 5000:5000 devops-portfolio-app:local
   ```

4. **Verify container health**:
   ```bash
   docker ps
   docker logs devops-app
   curl http://localhost:5000/health
   ```

5. **Inspect security**:
   ```bash
   docker inspect devops-app | grep -A 5 "User"
   ```
   **Expected**: User should be "1000" (non-root)

6. **Stop and remove**:
   ```bash
   docker stop devops-app
   docker rm devops-app
   ```

**Success Criteria**:
- ✅ Image builds under 150MB
- ✅ Container runs as non-root user (uid=1000)
- ✅ Health check passes
- ✅ Structured JSON logs visible in `docker logs`

### Phase 4: KIND Cluster Setup

**Objective**: Create a local Kubernetes cluster using KIND.

**Steps**:

1. **Create single-node cluster** (recommended for development):
   ```bash
   chmod +x scripts/setup-kind.sh
   ./scripts/setup-kind.sh single
   ```
   
   Or manually:
   ```bash
   kind create cluster --config kind/single-node.yaml --name devops-cluster
   ```

2. **Verify cluster**:
   ```bash
   kubectl cluster-info
   kubectl get nodes
   kubectl get pods -n kube-system
   ```
   **Expected**: Control plane running, node in Ready state

3. **Install NGINX Ingress Controller**:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
   kubectl wait --namespace ingress-nginx \
     --for=condition=ready pod \
     --selector=app.kubernetes.io/component=controller \
     --timeout=120s
   ```

4. **Verify ingress**:
   ```bash
   kubectl get pods -n ingress-nginx
   ```
   **Expected**: ingress-nginx-controller pod in Running state

**Success Criteria**:
- ✅ KIND cluster created successfully
- ✅ Node shows Ready status
- ✅ All kube-system pods running
- ✅ NGINX ingress controller deployed

### Phase 5: Kubernetes Deployment

**Objective**: Deploy the application to the KIND cluster.

**Steps**:

1. **Load local image into KIND**:
   ```bash
   kind load docker-image devops-portfolio-app:local --name devops-cluster
   ```

2. **Apply Kubernetes manifests**:
   ```bash
   kubectl apply -f kubernetes/
   ```

3. **Verify deployment**:
   ```bash
   kubectl get all -n devops-app
   kubectl get pods -n devops-app -w
   ```
   **Expected**: 2 pods in Running state

4. **Check pod logs**:
   ```bash
   kubectl logs -n devops-app -l app=devops-app --tail=50
   ```

5. **Port-forward to access application**:
   ```bash
   kubectl port-forward svc/devops-app 8080:80 -n devops-app
   ```

6. **Test endpoints** (in another terminal):
   ```bash
   curl http://localhost:8080/health
   curl http://localhost:8080/metrics
   ```

**Success Criteria**:
- ✅ Namespace created
- ✅ 2 pods running
- ✅ Service accessible via port-forward
- ✅ All health checks passing
- ✅ Prometheus metrics exposed

### Phase 6: Monitoring Stack Deployment

**Objective**: Deploy Prometheus and Grafana for observability.

**Steps**:

1. **Deploy monitoring stack**:
   ```bash
   kubectl apply -f monitoring/
   ```

2. **Verify monitoring pods**:
   ```bash
   kubectl get pods -n monitoring
   ```
   **Expected**: prometheus and grafana pods running

3. **Access Prometheus**:
   ```bash
   kubectl port-forward svc/prometheus 9090:9090 -n monitoring
   ```
   Open: http://localhost:9090
   
   **Verify**: Query `http_requests_total` to see application metrics

4. **Access Grafana**:
   ```bash
   kubectl port-forward svc/grafana 3000:3000 -n monitoring
   ```
   Open: http://localhost:3000 (admin/admin)
   
   **Verify**: Dashboards load with data

5. **Check ServiceMonitor**:
   ```bash
   kubectl get servicemonitor -n devops-app
   ```

**Success Criteria**:
- ✅ Prometheus scraping application metrics
- ✅ Grafana dashboards display data
- ✅ Alert rules configured
- ✅ ServiceMonitor detecting app pods

### Phase 7: CI/CD Pipeline Setup

**Objective**: Configure GitHub Actions for automated testing and deployment.

**Steps**:

1. **Fork the repository** on GitHub

2. **Enable GitHub Actions**:
   - Go to repository Settings → Actions → General
   - Set "Workflow permissions" to "Read and write permissions"
   - Enable "Allow GitHub Actions to create and approve pull requests"

3. **Configure GHCR access**:
   - No additional secrets needed (uses `GITHUB_TOKEN`)
   - Ensure "Packages: Write" permission is enabled

4. **Test CI workflow**:
   ```bash
   git checkout -b test-ci
   # Make a small change to app/main.py
   git add .
   git commit -m "test: trigger CI"
   git push origin test-ci
   ```
   
   **Verify**: CI workflow runs (lint, test, security scan)

5. **Test CD workflow**:
   ```bash
   git checkout main
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```
   
   **Verify**: CD workflow builds and pushes to GHCR

6. **Pull image from GHCR**:
   ```bash
   docker pull ghcr.io/ramiz-takildar/devops-portfolio-platform:v1.0.0
   ```

**Success Criteria**:
- ✅ CI workflow passes on PR
- ✅ CD workflow builds multi-arch image
- ✅ Image pushed to GHCR successfully
- ✅ Trivy scans complete without CRITICAL vulnerabilities
- ✅ SBOM generated

### Phase 8: GitOps with ArgoCD (Optional)

**Objective**: Automate deployments using ArgoCD.

**Steps**:

1. **Install ArgoCD**:
   ```bash
   cd argocd
   chmod +x install.sh
   ./install.sh
   ```

2. **Access ArgoCD UI**:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
   Open: https://localhost:8080
   
   Get password:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

3. **Create application**:
   ```bash
   kubectl apply -f argocd/application.yaml
   ```

4. **Sync application**:
   - In ArgoCD UI, click "Sync" on the application
   - Or via CLI:
   ```bash
   argocd app sync devops-portfolio-app
   ```

**Success Criteria**:
- ✅ ArgoCD installed and accessible
- ✅ Application synced successfully
- ✅ Auto-sync enabled for GitOps workflow

## Development Conventions

### Code Style and Quality

- **Linting**: `flake8` with max line length 120, ignoring E203 and W503
- **Formatting**: `black` for consistent code formatting (checked in CI, not enforced)
- **Testing**: `pytest` for unit tests with verbose output and short tracebacks
- **Coverage**: All endpoints must have corresponding tests

### Application Structure

The Flask application (`app/main.py`) follows these patterns:

1. **Structured JSON Logging**: All logs output as JSON with timestamp, level, logger, message, and context
2. **Prometheus Metrics**: 
   - `http_requests_total` (Counter): tracks all HTTP requests by method, endpoint, status
   - `http_request_duration_seconds` (Histogram): tracks request latency with 12 buckets
   - `http_errors_total` (Counter): tracks exceptions by type
3. **Security Headers**: All responses include `X-Content-Type-Options`, `X-Frame-Options`, `X-XSS-Protection`
4. **Health Endpoints**:
   - `/` - Welcome page with version info
   - `/health` - Liveness probe (always returns 200 if process alive)
   - `/ready` - Readiness probe (returns 200 when ready to serve traffic)
   - `/metrics` - Prometheus metrics endpoint
   - `/version` - Application version information

### Docker Best Practices

The `Dockerfile` implements:

- **Multi-stage builds**: Separate builder and runtime stages to minimize final image size
- **Non-root user**: Runs as `appuser` (uid=1000) for security
- **Alpine base**: Uses `python:3.12-alpine` for minimal attack surface (~142MB final image)
- **Layer caching**: Dependencies installed before copying application code
- **Virtual environment**: Isolated Python environment copied from builder
- **Production WSGI**: Uses Gunicorn with 2 workers, 4 threads per worker
- **Health checks**: Built-in Docker HEALTHCHECK using Python stdlib

### CI/CD Pipeline

**CI Workflow** (`.github/workflows/ci.yml`):
- Triggers on push/PR to `main` and `develop` branches
- Runs `flake8` linting with max-line-length=120
- Executes `pytest` unit tests with artifact upload
- Performs Trivy filesystem vulnerability scan (CRITICAL + HIGH)
- Uploads SARIF results to GitHub Security tab
- Fails on CRITICAL vulnerabilities

**CD Workflow** (`.github/workflows/cd.yml`):
- Triggers on push to `main` and version tags (`v*.*.*`)
- Builds multi-arch images (`linux/amd64`, `linux/arm64`)
- Scans built image with Trivy (fails on CRITICAL)
- Pushes to GHCR with semantic versioning tags
- Generates SPDX SBOM (Software Bill of Materials)
- Uses GitHub Actions cache for faster builds

### Kubernetes Manifests

All manifests in `kubernetes/` follow these conventions:

- **Namespace isolation**: Application runs in `devops-app` namespace
- **Resource limits**: CPU and memory requests/limits defined
- **Security context**: `runAsNonRoot: true`, `allowPrivilegeEscalation: false`, drop all capabilities
- **Probes**: Liveness, readiness, and startup probes configured
- **ConfigMaps**: Non-sensitive configuration (APP_NAME, APP_ENV, LOG_LEVEL)
- **Secrets**: Sensitive data (base64 encoded, demo values only)
- **Rolling updates**: `maxSurge: 1`, `maxUnavailable: 0` for zero-downtime deployments
- **Replicas**: 2 replicas for high availability

### Monitoring Configuration

Prometheus (`monitoring/prometheus-config.yaml`):
- Scrapes Kubernetes pods with `prometheus.io/scrape: "true"` annotation
- 15-day retention period
- ServiceMonitor for automatic service discovery
- Alert rules for high CPU, memory, and pod crash loops

Grafana (`monitoring/grafana-deployment.yaml`):
- Pre-configured dashboards via ConfigMap
- Prometheus datasource auto-provisioned
- Anonymous access enabled (for demo purposes)
- NodePort 30000 for external access

### Security Practices

1. **Container Security**:
   - Non-root user (uid=1000)
   - Read-only root filesystem where possible
   - No privileged containers
   - Drop all Linux capabilities

2. **Vulnerability Scanning**:
   - Trivy scans in CI/CD pipeline
   - Fail on CRITICAL vulnerabilities
   - SARIF results uploaded to GitHub Security

3. **Secrets Management**:
   - Never commit real secrets to repository
   - Use Kubernetes Secrets (base64 encoded)
   - Consider Sealed Secrets or External Secrets Operator for production

4. **Network Security**:
   - ClusterIP services by default
   - Ingress for controlled external access
   - Consider NetworkPolicy for pod-to-pod segmentation

### Testing Strategy

- **Unit Tests**: 14 tests in `app/tests/test_app.py` covering all endpoints
- **Integration Tests**: Placeholder in `tests/` directory
- **Smoke Tests**: Verify endpoints respond correctly after deployment
- **Load Tests**: Not implemented (consider adding for production readiness)

## Common Commands

### Development

```bash
make help           # Show all available commands
make build          # Build Docker image
make test           # Run unit tests
make lint           # Run flake8 linting
```

### Kubernetes

```bash
make kind-up        # Create KIND cluster
make kind-down      # Delete KIND cluster
make deploy-local   # Deploy to local KIND
make port-forward   # Forward Grafana and Prometheus ports
```

### Cleanup

```bash
make clean          # Remove containers and images
make stop           # Stop running container
```

## Troubleshooting Guide

### Port 5000 Conflicts (macOS)

**Issue**: macOS Control Center uses port 5000

**Solution**:
```bash
docker run -d -p 8888:5000 devops-portfolio-app:local
# Or update Makefile to use different port
```

### ImagePullBackOff in Kubernetes

**Issue**: Pod cannot pull image from local Docker

**Solution**:
```bash
# Load image into KIND cluster
kind load docker-image devops-portfolio-app:local --name devops-cluster

# Or update deployment to use local image
kubectl set image deployment/devops-app app=devops-portfolio-app:local -n devops-app
```

### KIND Cluster Creation Fails

**Issue**: Insufficient Docker resources

**Solution**:
- Ensure Docker has 4+ CPU and 8GB+ RAM allocated
- Check Docker Desktop → Settings → Resources
- Delete and recreate cluster:
```bash
kind delete cluster --name devops-cluster
kind create cluster --config kind/single-node.yaml
```

### Prometheus Not Scraping Metrics

**Issue**: No metrics visible in Prometheus

**Solution**:
```bash
# Verify pod has correct annotation
kubectl get pods -n devops-app -o yaml | grep prometheus.io/scrape

# Check ServiceMonitor
kubectl get servicemonitor -n devops-app

# Check Prometheus targets
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
# Open http://localhost:9090/targets
```

### Grafana Dashboards Missing

**Issue**: Dashboards not loading in Grafana

**Solution**:
```bash
# Verify ConfigMap is mounted
kubectl describe pod -n monitoring -l app=grafana

# Check dashboard provider
kubectl get configmap -n monitoring grafana-dashboard-provider -o yaml

# Restart Grafana pod
kubectl rollout restart deployment/grafana -n monitoring
```

### CI/CD Pipeline Failures

**Issue**: GitHub Actions workflow fails

**Solution**:
- Check workflow logs in GitHub Actions tab
- Verify Python version matches (3.12)
- Ensure all dependencies in requirements.txt
- Run tests locally first: `cd app && pytest tests/ -v`
- For Trivy failures, check for CRITICAL vulnerabilities

## Production Considerations

When adapting this project for production:

1. **Secrets Management**:
   - Replace demo secrets with proper secret management
   - Use Sealed Secrets, Vault, or External Secrets Operator
   - Never commit real credentials

2. **Persistence**:
   - Use PersistentVolumeClaims instead of emptyDir
   - Configure backup strategy with Velero
   - Set up proper retention policies

3. **TLS/SSL**:
   - Enable cert-manager for automatic certificate management
   - Configure TLS on Ingress
   - Use Let's Encrypt for certificates

4. **High Availability**:
   - Add PodDisruptionBudget for critical services
   - Configure proper resource requests/limits based on load testing
   - Use multiple replicas across availability zones

5. **Networking**:
   - Implement NetworkPolicy for pod-to-pod segmentation
   - Consider service mesh (Istio/Linkerd) for advanced traffic management
   - Set up proper DNS and load balancing

6. **Monitoring & Alerting**:
   - Configure proper alerting channels (Slack, PagerDuty, email)
   - Set up log aggregation (ELK, Loki)
   - Implement distributed tracing (Jaeger, Tempo)

7. **Authentication**:
   - Use OAuth/SAML for Grafana instead of anonymous access
   - Implement proper RBAC for Kubernetes
   - Set up SSO for all services

## File Modification Guidelines

When modifying files:

### Application Code (`app/main.py`)
- Maintain structured JSON logging format
- Keep Prometheus metrics instrumentation
- Preserve security headers on all responses
- Update tests when adding new endpoints
- Follow 12-factor app principles

### Dockerfile
- Keep multi-stage build pattern
- Maintain non-root user
- Preserve Alpine base for minimal size
- Update HEALTHCHECK if endpoints change
- Document any new dependencies

### Kubernetes Manifests
- Keep security context settings
- Maintain probe configurations
- Update ConfigMap/Secret references consistently
- Test changes in local KIND cluster first
- Document resource limit changes

### CI/CD Workflows
- Keep Trivy security scans
- Maintain multi-arch build support
- Preserve SARIF upload for security visibility
- Test workflow changes in feature branches
- Update documentation for new steps

### Monitoring
- Update Grafana dashboards when adding new metrics
- Keep Prometheus scrape configurations aligned with ServiceMonitor
- Test alert rules before deploying
- Document new metrics in README

## Key Design Decisions

1. **KIND over Minikube**: KIND is faster, more lightweight, and better suited for CI/CD integration
2. **Alpine over Debian**: Smaller image size (~142MB vs ~300MB+) with adequate functionality
3. **Gunicorn over Flask dev server**: Production-grade WSGI server with worker management
4. **JSON logging**: Structured logs are easier to parse and query in production systems
5. **Multi-arch builds**: Support both x86 and ARM architectures for broader compatibility
6. **ServiceMonitor over static scrape configs**: Automatic service discovery as deployments scale
7. **ConfigMap + Secret separation**: Clear distinction between sensitive and non-sensitive configuration

## Repository Maintenance

- **Branch Strategy**: `main` for production-ready code, `develop` for integration
- **Version Tags**: Use semantic versioning (`v1.0.0`, `v1.1.0`, etc.)
- **Pull Requests**: Required for all changes to `main` branch
- **CI Checks**: All CI checks must pass before merging
- **Documentation**: Update relevant docs with each feature addition
- **Security**: Regular dependency updates and vulnerability scans

## Additional Resources

- **Documentation**: See `docs/` directory for detailed guides
- **Architecture**: Review `docs/ARCHITECTURE.md` for design decisions
- **Troubleshooting**: Check `docs/TROUBLESHOOTING.md` for common issues
- **CI/CD**: Read `docs/CI_CD_GUIDE.md` for pipeline details
- **KIND Setup**: Follow `docs/KIND_SETUP.md` for cluster configuration
- **Production Enhancements**: See `docs/PRODUCTION_ENHANCEMENTS.md` for 24 advanced features to implement for learning (security, observability, HA, performance, GitOps, service mesh, backup/DR, cost optimization)