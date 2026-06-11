# DevOps Portfolio Platform

[![CI](https://github.com/YOUR_USERNAME/devops-portfolio-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/devops-portfolio-platform/actions/workflows/ci.yml)
[![CD](https://github.com/YOUR_USERNAME/devops-portfolio-platform/actions/workflows/cd.yml/badge.svg)](https://github.com/YOUR_USERNAME/devops-portfolio-platform/actions/workflows/cd.yml)

A production-grade end-to-end DevOps platform built around a Python Flask application running on a local KIND (Kubernetes in Docker) cluster. This project demonstrates real-world enterprise DevOps, SRE, and Platform Engineering practices suitable for a technical portfolio.

## Architecture

```
Developer → GitHub → GitHub Actions → Docker Build → GHCR → KIND Cluster → Prometheus → Grafana → Alerting
```

### Component Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              DEVELOPER WORKSTATION                           │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────────────────────┐ │
│  │ Flask App   │  │ pytest Tests │  │ Local Docker Build & Test           │ │
│  │ (app/)      │  │ (app/tests/) │  │ (docker build / docker run / curl)  │ │
│  └─────────────┘  └──────────────┘  └─────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                    GITHUB                                   │
│  ┌────────────────────────────────────┐  ┌────────────────────────────────┐ │
│  │ CI Workflow (ci.yml)               │  │ CD Workflow (cd.yml)           │ │
│  │ • flake8 lint                      │  │ • Multi-arch Docker build      │ │
│  │ • pytest unit tests                │  │ • Trivy image scan             │ │
│  │ • Trivy filesystem scan            │  │ • Push to GHCR                 │ │
│  │                                    │  │ • KIND deploy validation       │ │
│  └────────────────────────────────────┘  └────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            GITHUB CONTAINER REGISTRY                        │
│                        ghcr.io/username/devops-portfolio-app                │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              KIND CLUSTER (K8s)                             │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │  devops-app Namespace                                                   │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐   │ │
│  │  │ Deployment  │  │ Service     │  │ Ingress     │  │ HPA        │   │ │
│  │  │ (2 replicas)│  │ (ClusterIP) │  │ (NGINX)     │  │ (2-10 pods)│   │ │
│  │  │ • Liveness  │  │ Port 80     │  │ devops-app  │  │ CPU 70%    │   │ │
│  │  │ • Readiness │  │ Target 5000 │  │ .local      │  │ Mem 80%    │   │ │
│  │  │ • Startup   │  └─────────────┘  └─────────────┘  └────────────┘   │ │
│  │  └─────────────┘                                                        │ │
│  │  ConfigMap (app config)  │  Secret (sensitive data)                     │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │  monitoring Namespace                                                   │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌────────────────────────┐  │ │
│  │  │ Prometheus      │  │ Grafana         │  │ Alert Rules            │  │ │
│  │  │ • Pod scraping  │  │ • Dashboards    │  │ • High CPU             │  │ │
│  │  │ • Service disc. │  │ • Prometheus DS │  │ • High Memory          │  │ │
│  │  │ • 15d retention │  │ • NodePort 30000│  │ • Pod Crash Loop       │  │ │
│  │  └─────────────────┘  └─────────────────┘  └────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Application | Python Flask | Web application with REST API |
| Metrics | prometheus-client | Application metrics instrumentation |
| Containerization | Docker | Multi-stage builds, non-root containers |
| Base Image | python:3.12-alpine | Minimal, secure runtime |
| CI/CD | GitHub Actions | Automated lint, test, build, scan, deploy |
| Registry | GHCR | Container image publishing |
| Orchestration | Kubernetes (KIND) | Local cluster for development |
| Monitoring | Prometheus | Metrics collection and alerting |
| Visualization | Grafana | Dashboards and observability |
| Security | Trivy | Vulnerability scanning |

## Repository Structure

```
project-root/
├── app/                          # Flask application source
│   ├── main.py                   # Application with 5 endpoints
│   ├── requirements.txt          # Python dependencies (Flask, prometheus-client, gunicorn)
│   └── tests/                    # pytest unit tests (14 tests)
│       └── test_app.py
├── kubernetes/                   # Kubernetes manifests
│   ├── namespace.yaml            # devops-app namespace
│   ├── configmap.yaml            # Non-sensitive app configuration
│   ├── secret.yaml               # Sensitive data (demo values)
│   ├── deployment.yaml           # App deployment (2 replicas, probes, security)
│   ├── service.yaml              # ClusterIP service
│   ├── ingress.yaml              # NGINX ingress routing
│   └── hpa.yaml                  # Horizontal Pod Autoscaler (2-10 replicas)
├── monitoring/                   # Observability stack
│   ├── dashboards/               # Grafana dashboard JSON
│   │   ├── infrastructure.json   # CPU, Memory, Pod Status, Restarts, Cluster Health
│   │   └── application.json      # Request Rate, Error Rate, Response Time
│   ├── namespace.yaml            # monitoring namespace
│   ├── prometheus-rbac.yaml      # ServiceAccount, ClusterRole, ClusterRoleBinding
│   ├── prometheus-config.yaml    # Prometheus scrape configuration
│   ├── prometheus-deployment.yaml # Prometheus server deployment
│   ├── grafana-deployment.yaml   # Grafana server deployment
│   ├── grafana-dashboard-provider.yaml # Dashboard provisioning config
│   ├── grafana-dashboards-configmap.yaml # Dashboard JSON ConfigMap
│   ├── servicemonitor.yaml       # ServiceMonitor for app metrics
│   └── alert-rules.yaml          # Prometheus alerting rules
├── kind/                         # KIND cluster configurations
│   ├── single-node.yaml          # 1 control-plane cluster
│   └── multi-node.yaml           # 1 control-plane + 2 workers
├── scripts/                      # Helper scripts
│   └── setup-kind.sh             # Cluster bootstrap script
├── docs/                         # Documentation
│   ├── KIND_SETUP.md             # KIND installation guide
│   ├── CI_CD_GUIDE.md            # CI/CD pipeline documentation
│   ├── TROUBLESHOOTING.md        # Common issues and resolutions
│   └── ARCHITECTURE.md           # System architecture and design decisions
├── tests/                        # Integration & e2e tests
├── .github/workflows/            # GitHub Actions pipelines
│   ├── ci.yml                    # Lint, test, Trivy filesystem scan
│   └── cd.yml                    # Multi-arch build, Trivy image scan, GHCR push, KIND validate
├── Dockerfile                    # Multi-stage Dockerfile (142MB, non-root)
├── .dockerignore                 # Docker build context exclusions
├── Makefile                      # Common development commands
└── README.md                     # This file
```

## Quick Start

### Prerequisites

- Docker 24.0+
- kubectl 1.30+
- KIND 0.23+
- Python 3.12 (for local development)

### Phase 1: Local Application Development

```bash
# Install dependencies
cd app && pip install -r requirements.txt

# Run unit tests
python -m pytest tests/ -v
# Expected: 14 passed

# Run application locally
python main.py
# Open: http://localhost:5000/health
```

### Phase 2: Docker Build

```bash
# Build image (target: <150MB)
docker build -t devops-app:local .

# Verify image size
docker images devops-app:local --format "{{.Size}}"
# Expected: ~142MB

# Run container
docker run -d --name devops-app -p 5000:5000 devops-app:local

# Verify endpoints
curl http://localhost:5000/health
curl http://localhost:5000/ready
curl http://localhost:5000/metrics
curl http://localhost:5000/version
```

### Phase 3: KIND Cluster Setup

```bash
# Create single-node cluster
chmod +x scripts/setup-kind.sh
./scripts/setup-kind.sh single

# Or create multi-node cluster
./scripts/setup-kind.sh multi

# Verify cluster
kubectl get nodes
kubectl cluster-info
```

### Phase 4: Kubernetes Deployment

```bash
# Load local image into KIND
docker build -t devops-app:local .
kind load docker-image devops-app:local --name devops-cluster

# Apply manifests
kubectl apply -f kubernetes/

# For local testing, update image to local build
kubectl set image deployment/devops-app app=devops-app:local -n devops-app

# Verify deployment
kubectl get pods -n devops-app
kubectl get svc -n devops-app
kubectl get ingress -n devops-app

# Test via port-forward
kubectl port-forward svc/devops-app 8080:80 -n devops-app
curl http://localhost:8080/health
```

### Phase 5: Observability Stack

```bash
# Apply monitoring manifests
kubectl apply -f monitoring/

# Verify monitoring pods
kubectl get pods -n monitoring

# Access Prometheus
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
# Open: http://localhost:9090

# Access Grafana
kubectl port-forward svc/grafana 3000:3000 -n monitoring
# Open: http://localhost:3000 (admin / admin)
```

## Endpoints

| Endpoint | Method | Purpose | Probe Type |
|----------|--------|---------|-----------|
| `/` | GET | Welcome page with version info | — |
| `/health` | GET | Liveness probe | Liveness |
| `/ready` | GET | Readiness probe | Readiness |
| `/metrics` | GET | Prometheus metrics | — |
| `/version` | GET | Application version | — |

## CI/CD Pipeline

### CI (`github/workflows/ci.yml`)

Triggered on push/PR to `main` and `develop`:

1. **Lint**: `flake8` code quality + `black` format check
2. **Unit Tests**: `pytest` with artifact upload
3. **Security Scan**: Trivy filesystem vulnerability scan (CRITICAL + HIGH)

### CD (`github/workflows/cd.yml`)

Triggered on push to `main` and version tags:

1. **Build**: Multi-arch Docker image (`linux/amd64`, `linux/arm64`)
2. **Image Scan**: Trivy container vulnerability scan (fail on CRITICAL)
3. **Publish**: Push to GHCR with semantic versioning tags
4. **SBOM**: Generate SPDX software bill of materials
5. **Validate**: Deploy to KIND and run smoke tests

## Security

- Container runs as non-root user (`uid=1000`)
- Multi-stage Docker build minimizes attack surface
- No build tools in production image
- Security headers on all HTTP responses (X-Content-Type-Options, X-Frame-Options, X-XSS-Protection)
- Trivy vulnerability scans in CI/CD
- Kubernetes security context: `runAsNonRoot`, `allowPrivilegeEscalation: false`, `capabilities: drop ALL`
- No secrets committed to repository (demo placeholder only)

## Makefile Commands

```bash
make build          # Build Docker image
make test           # Run unit tests
make lint           # Run flake8
make kind-up        # Create KIND cluster
make deploy-local   # Deploy to KIND
make port-forward   # Forward Grafana + Prometheus
make clean          # Remove containers and images
```

## Production Considerations

- Use **Sealed Secrets** or **External Secrets Operator** for sensitive data
- Replace emptyDir volumes with **PersistentVolumeClaims** for data retention
- Install **cert-manager** for automatic TLS on Ingress
- Enable **PodDisruptionBudget** for high availability
- Add **NetworkPolicy** for pod-to-pod network segmentation
- Consider **Istio/Linkerd** service mesh for advanced traffic management
- Use **Velero** for cluster backup and disaster recovery
- Replace Grafana anonymous auth with **OAuth/SAML** integration

## Validation Checklist

- [ ] Application responds to all 5 endpoints
- [ ] pytest passes all 14 tests
- [ ] Docker image builds successfully and is under 150MB
- [ ] Container runs as non-root user (uid=1000)
- [ ] KIND cluster creates successfully
- [ ] Kubernetes pods reach Running status
- [ ] Prometheus collects metrics
- [ ] Grafana dashboards load correctly
- [ ] CI workflow passes (flake8, pytest, Trivy)
- [ ] CD workflow builds and pushes multi-arch image

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for detailed troubleshooting guide.

### Common Issues

**Port 5000 already in use (macOS)**
```bash
# macOS Control Center uses port 5000
# Use a different host port
docker run -d -p 8888:5000 devops-app:local
```

**KIND cluster creation fails**
```bash
# Ensure Docker has sufficient resources (4 CPU, 8GB RAM)
# Delete and recreate
kind delete cluster --name devops-cluster
kind create cluster --config kind/single-node.yaml
```

**ImagePullBackOff on deployment**
```bash
# Load local image into KIND
kind load docker-image devops-app:local --name devops-cluster
# Or update deployment to use local image
kubectl set image deployment/devops-app app=devops-app:local -n devops-app
```

**HPA shows <unknown> for current metrics**
```bash
# Install metrics-server for HPA to work
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## License

MIT
