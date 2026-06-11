# DevOps Portfolio Platform

[![CI](https://github.com/Ramiz-Takildar/devops-portfolio-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/Ramiz-Takildar/devops-portfolio-platform/actions/workflows/ci.yml)
[![CD](https://github.com/Ramiz-Takildar/devops-portfolio-platform/actions/workflows/cd.yml/badge.svg)](https://github.com/Ramiz-Takildar/devops-portfolio-platform/actions/workflows/cd.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)](https://www.python.org/)

> **A production-grade, end-to-end DevOps platform demonstrating enterprise-level practices for containerization, orchestration, CI/CD, observability, and security—all running locally on your machine.**

Perfect for DevOps engineers, SREs, and Platform Engineers looking to build a comprehensive portfolio project or learn production-ready practices.

---

## 🌟 Key Features

- **🚀 One-Click Installation** - Get the entire platform running in 5-10 minutes
- **🔒 Security-First** - Non-root containers, vulnerability scanning, security contexts
- **📊 Full Observability** - Prometheus metrics, Grafana dashboards, structured logging
- **🔄 GitOps Ready** - Optional ArgoCD integration for continuous deployment
- **🏗️ Production Patterns** - 12-factor app, multi-stage builds, health checks, rolling updates
- **📈 Auto-Scaling** - Horizontal Pod Autoscaler ready with metrics-server
- **🛡️ CI/CD Pipeline** - Automated testing, linting, security scanning, multi-arch builds
- **📚 Comprehensive Docs** - Step-by-step guides, troubleshooting, 24 production enhancements

---

## 📋 Table of Contents

- [What You'll Learn](#-what-youll-learn)
- [Architecture](#-architecture)
- [Technology Stack](#-technology-stack)
- [Quick Start](#-quick-start)
  - [One-Click Installation](#one-click-installation)
  - [Manual Installation](#manual-installation)
- [Application Endpoints](#-application-endpoints)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Security](#-security)
- [Monitoring & Observability](#-monitoring--observability)
- [Production Enhancements](#-production-ready-enhancements)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎓 What You'll Learn

By implementing and exploring this platform, you'll gain hands-on experience with:

### DevOps Fundamentals
- ✅ Containerization with Docker (multi-stage builds, security hardening)
- ✅ Kubernetes orchestration (deployments, services, ingress, configmaps, secrets)
- ✅ CI/CD pipelines with GitHub Actions
- ✅ GitOps workflows with ArgoCD

### Site Reliability Engineering (SRE)
- ✅ Observability (metrics, logs, dashboards)
- ✅ Service Level Indicators (SLIs) and Objectives (SLOs)
- ✅ Alerting and incident management
- ✅ High availability and resilience patterns

### Security & Compliance
- ✅ Container security (non-root users, capability dropping)
- ✅ Vulnerability scanning with Trivy
- ✅ Secrets management
- ✅ Network policies and RBAC

### Platform Engineering
- ✅ Infrastructure as Code (IaC)
- ✅ Configuration management
- ✅ Multi-environment deployments
- ✅ Automated rollbacks and canary deployments

---

## 🏗️ Architecture

```
Developer → Git → GitHub Actions → Docker Build → GHCR → ArgoCD → KIND Cluster → Prometheus → Grafana
```

### Component Flow

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
│  │                                    │  │ • SBOM generation              │ │
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
│                              ARGOCD (GitOps)                                │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │ • Monitors Git repository for changes                                   │ │
│  │ • Automatically syncs Kubernetes manifests                              │ │
│  │ • Provides declarative continuous deployment                            │ │
│  │ • Web UI for deployment visualization                                   │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              KIND CLUSTER (K8s)                             │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │  devops-app Namespace                                                   │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                   │ │
│  │  │ Deployment  │  │ Service     │  │ Ingress     │                   │ │
│  │  │ (2 replicas)│  │ (ClusterIP) │  │ (NGINX)     │                   │ │
│  │  │ • Liveness  │  │ Port 80     │  │ devops-app  │                   │ │
│  │  │ • Readiness │  │ Target 5000 │  │ .local      │                   │ │
│  │  │ • Startup   │  └─────────────┘  └─────────────┘                   │ │
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
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │  argocd Namespace (Optional)                                            │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌────────────────────────┐  │ │
│  │  │ ArgoCD Server   │  │ Repo Server     │  │ Application Controller │  │ │
│  │  │ • Web UI        │  │ • Git sync      │  │ • K8s reconciliation   │  │ │
│  │  │ • API           │  │ • Manifest gen  │  │ • Health checks        │  │ │
│  │  └─────────────────┘  └─────────────────┘  └────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Application** | Python 3.12 + Flask | Web application with REST API |
| **WSGI Server** | Gunicorn | Production-grade application server |
| **Metrics** | prometheus-client | Application metrics instrumentation |
| **Containerization** | Docker | Multi-stage builds, non-root containers |
| **Base Image** | python:3.12-alpine | Minimal, secure runtime (~142MB) |
| **CI/CD** | GitHub Actions | Automated lint, test, build, scan, deploy |
| **Registry** | GHCR | Container image publishing |
| **Orchestration** | Kubernetes (KIND) | Local cluster for development |
| **Monitoring** | Prometheus | Metrics collection and alerting |
| **Visualization** | Grafana | Dashboards and observability |
| **Security** | Trivy | Vulnerability scanning (SARIF) |
| **GitOps** | ArgoCD (optional) | Continuous deployment automation |

---

## 🚀 Quick Start

### One-Click Installation

**Get the entire platform running in 5-10 minutes:**

```bash
# Clone the repository
git clone https://github.com/Ramiz-Takildar/devops-portfolio-platform.git
cd devops-portfolio-platform

# Run one-click installation
chmod +x install.sh
./install.sh
```

#### Installation Options

| Command | Description |
|---------|-------------|
| `./install.sh` | Full installation (recommended) |
| `./install.sh --skip-prereqs` | Skip prerequisite checks |
| `./install.sh --multi-node` | Create multi-node cluster (1 control-plane + 2 workers) |
| `./install.sh --no-monitoring` | Skip monitoring stack deployment |
| `./install.sh --argocd` | Install ArgoCD for GitOps automation |
| `./install.sh --help` | Show all available options |

#### What Gets Installed

The script automatically:

1. ✅ **Checks prerequisites** - Docker, kubectl, KIND, Python 3.12
2. ✅ **Installs dependencies** - Python packages via pip
3. ✅ **Runs tests** - 14 unit tests with pytest
4. ✅ **Builds Docker image** - Multi-stage build (~142MB)
5. ✅ **Creates KIND cluster** - Single or multi-node Kubernetes cluster
6. ✅ **Installs NGINX Ingress** - For external access
7. ✅ **Deploys application** - 2 replicas with health checks
8. ✅ **Deploys monitoring** - Prometheus + Grafana with dashboards
9. ✅ **Verifies deployment** - Checks all components are running

**⏱️ Estimated Time**: 5-10 minutes (depending on internet speed)

#### Post-Installation Access

After installation, you'll see commands to access:

```bash
# Application
kubectl port-forward svc/devops-app 8080:80 -n devops-app
curl http://localhost:8080/health

# Grafana (admin/admin)
kubectl port-forward svc/grafana 3000:3000 -n monitoring
open http://localhost:3000

# Prometheus
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
open http://localhost:9090

# ArgoCD (if installed)
kubectl port-forward svc/argocd-server 8443:443 -n argocd
open https://localhost:8443
```

---

### Manual Installation

<details>
<summary><b>Click to expand manual installation steps</b></summary>

#### Prerequisites

- Docker 24.0+ (with 4+ CPU, 8GB+ RAM)
- kubectl 1.30+
- KIND 0.23+
- Python 3.12+ (for local development)

#### Phase 1: Local Application Development

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

#### Phase 2: Docker Build

```bash
# Build image (target: <150MB)
docker build -t devops-portfolio-app:local .

# Verify image size
docker images devops-portfolio-app:local --format "{{.Size}}"
# Expected: ~142MB

# Run container
docker run -d --name devops-app -p 5000:5000 devops-portfolio-app:local

# Verify endpoints
curl http://localhost:5000/health
curl http://localhost:5000/ready
curl http://localhost:5000/metrics
curl http://localhost:5000/version
```

#### Phase 3: KIND Cluster Setup

```bash
# Create single-node cluster
kind create cluster --config kind/single-node.yaml --name devops-cluster

# Or create multi-node cluster
kind create cluster --config kind/multi-node.yaml --name devops-cluster

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

#### Phase 4: Kubernetes Deployment

```bash
# Load local image into KIND
kind load docker-image devops-portfolio-app:local --name devops-cluster

# Apply manifests
kubectl apply -f kubernetes/

# Verify deployment
kubectl get all -n devops-app
kubectl get pods -n devops-app -w

# Test via port-forward
kubectl port-forward svc/devops-app 8080:80 -n devops-app
curl http://localhost:8080/health
```

#### Phase 5: Monitoring Stack

```bash
# Deploy Prometheus and Grafana
kubectl apply -f monitoring/

# Verify monitoring pods
kubectl get pods -n monitoring

# Access Grafana (admin/admin)
kubectl port-forward svc/grafana 3000:3000 -n monitoring
open http://localhost:3000

# Access Prometheus
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
open http://localhost:9090
```

</details>

---

## 🌐 Application Endpoints

| Endpoint | Method | Purpose | Probe Type |
|----------|--------|---------|-----------|
| `/` | GET | Welcome page with version info | — |
| `/health` | GET | Liveness probe (always returns 200 if alive) | Liveness |
| `/ready` | GET | Readiness probe (returns 200 when ready) | Readiness |
| `/metrics` | GET | Prometheus metrics (OpenMetrics format) | — |
| `/version` | GET | Application version and environment | — |

**Example Requests:**

```bash
# Health check
curl http://localhost:8080/health
# {"status":"healthy","timestamp":"2024-01-15T10:30:00.000Z"}

# Metrics
curl http://localhost:8080/metrics
# http_requests_total{method="GET",endpoint="health",status_code="200"} 42
# http_request_duration_seconds_bucket{method="GET",endpoint="health",le="0.005"} 40
```

---

## 🔄 CI/CD Pipeline

### Continuous Integration (CI)

**Triggers**: Push/PR to `main` or `develop` branches

| Job | Tools | Purpose |
|-----|-------|---------|
| **Lint** | flake8, black | Code quality and formatting checks |
| **Test** | pytest | Unit test execution (14 tests) |
| **Security Scan** | Trivy | Filesystem vulnerability detection |

**Features**:
- ⚡ Pip caching for faster builds
- 🔄 Concurrency control (cancels previous runs)
- 📊 Test result artifacts
- 🔒 SARIF upload to GitHub Security tab

### Continuous Deployment (CD)

**Triggers**: Push to `main` or version tags (`v*.*.*`)

| Step | Tool | Purpose |
|------|------|---------|
| **Build** | Docker Buildx | Multi-arch images (AMD64 + ARM64) |
| **Scan** | Trivy | Container vulnerability detection |
| **Publish** | GHCR | Push to GitHub Container Registry |
| **SBOM** | Trivy | Generate Software Bill of Materials |

**Features**:
- 🏗️ Multi-architecture support (x86 + ARM)
- 🏷️ Semantic versioning (v1.2.3, v1.2, v1, latest)
- 🔒 Fails on CRITICAL vulnerabilities
- 📦 SPDX SBOM generation
- ⚡ GitHub Actions cache for faster builds

---

## 🔒 Security

### Container Security

- ✅ **Non-root user** - Runs as uid=1000 (appuser)
- ✅ **Multi-stage builds** - No build tools in production image
- ✅ **Minimal base** - Alpine Linux (~142MB total)
- ✅ **Read-only filesystem** - Where possible
- ✅ **Dropped capabilities** - All Linux capabilities dropped
- ✅ **No privilege escalation** - `allowPrivilegeEscalation: false`

### Application Security

- ✅ **Security headers** - X-Content-Type-Options, X-Frame-Options, X-XSS-Protection
- ✅ **Structured logging** - JSON format with context
- ✅ **Health checks** - Liveness, readiness, startup probes
- ✅ **Resource limits** - CPU and memory constraints

### CI/CD Security

- ✅ **Vulnerability scanning** - Trivy scans on every build
- ✅ **SARIF reports** - Uploaded to GitHub Security tab
- ✅ **SBOM generation** - Software Bill of Materials (SPDX)
- ✅ **Fail on CRITICAL** - Pipeline fails on critical vulnerabilities

### Kubernetes Security

- ✅ **Security contexts** - runAsNonRoot, seccomp profiles
- ✅ **Network policies** - (Optional enhancement)
- ✅ **RBAC** - Least-privilege service accounts
- ✅ **Secrets management** - Base64 encoded (use Sealed Secrets in production)

---

## 📊 Monitoring & Observability

### Prometheus Metrics

**Application Metrics**:
- `http_requests_total` - Total HTTP requests by method, endpoint, status
- `http_request_duration_seconds` - Request latency histogram (12 buckets)
- `http_errors_total` - Total errors by type

**Infrastructure Metrics**:
- CPU usage per pod
- Memory usage per pod
- Pod restart count
- Network I/O

### Grafana Dashboards

**Infrastructure Dashboard**:
- CPU usage by pod
- Memory usage by pod
- Pod status and health
- Pod restart trends
- Cluster resource utilization

**Application Dashboard**:
- Request rate (requests/sec)
- Error rate (%)
- Response time (p50, p95, p99)
- Status code distribution

### Alerting Rules

- 🚨 High CPU usage (>80% for 5 minutes)
- 🚨 High memory usage (>80% for 5 minutes)
- 🚨 Pod crash loop (3+ restarts in 10 minutes)
- 🚨 High error rate (>5% for 5 minutes)

---

## 🎯 Production-Ready Enhancements

Want to take this platform to the next level? Check out [**docs/PRODUCTION_ENHANCEMENTS.md**](docs/PRODUCTION_ENHANCEMENTS.md) for **24 advanced features** you can implement:

### 🔒 Security (4 enhancements)
1. **Network Policies** - Zero-trust pod-to-pod communication
2. **Sealed Secrets** - Encrypt secrets in Git
3. **Pod Security Standards** - Enforce security best practices
4. **RBAC** - Least-privilege service accounts

### 📊 Observability (4 enhancements)
5. **Distributed Tracing** - Jaeger for request tracking
6. **Centralized Logging** - Loki for log aggregation
7. **SLO Dashboards** - Service Level Objectives and error budgets
8. **AlertManager** - Multi-channel alerting (Slack, PagerDuty)

### 🏗️ High Availability (4 enhancements)
9. **Pod Disruption Budgets** - Maintain availability during maintenance
10. **Horizontal Pod Autoscaler** - Auto-scale based on metrics
11. **Readiness Gates** - Custom readiness checks
12. **Circuit Breakers** - Prevent cascading failures

### ⚡ Performance (3 enhancements)
13. **Redis Cache** - Reduce database load
14. **Connection Pooling** - Optimize database connections
15. **CDN Simulation** - Nginx reverse proxy/cache

### 🔄 GitOps & Automation (3 enhancements)
16. **Multi-Environment** - Dev, staging, prod with Kustomize
17. **Automated Rollback** - Automatic failure recovery
18. **Pre-deployment Validation** - Smoke tests before promotion

### 🌐 Networking & Service Mesh (2 enhancements)
19. **Istio Service Mesh** - Advanced traffic management
20. **TLS with cert-manager** - Automatic certificate management

### 💾 Backup & DR (2 enhancements)
21. **Velero** - Cluster backup and disaster recovery
22. **Database Backups** - Automated CronJob backups

### 💰 Cost Optimization (2 enhancements)
23. **Resource Quotas** - Limit resource consumption
24. **Vertical Pod Autoscaler** - Right-size pods automatically

**Each enhancement includes**:
- ✅ Complete implementation code
- ✅ Step-by-step instructions
- ✅ Learning objectives
- ✅ Real-world use cases
- ✅ 8-week implementation roadmap

---

## 🛠️ Makefile Commands

```bash
make help           # Show all available commands
make build          # Build Docker image
make test           # Run unit tests
make lint           # Run flake8 linting
make kind-up        # Create KIND cluster
make kind-down      # Delete KIND cluster
make deploy-local   # Deploy to local KIND
make port-forward   # Forward Grafana + Prometheus ports
make clean          # Remove containers and images
make stop           # Stop running container
```

---

## ✅ Validation Checklist

Use this checklist to verify your deployment:

- [ ] Application responds to all 5 endpoints
- [ ] pytest passes all 14 tests
- [ ] Docker image builds successfully and is under 150MB
- [ ] Container runs as non-root user (uid=1000)
- [ ] KIND cluster creates successfully
- [ ] Kubernetes pods reach Running status (2 replicas)
- [ ] Prometheus collects application metrics
- [ ] Grafana dashboards load with data
- [ ] CI workflow passes (flake8, pytest, Trivy)
- [ ] CD workflow builds and pushes multi-arch image
- [ ] Health checks pass (liveness, readiness)
- [ ] Logs are structured JSON format
- [ ] Security context enforced (non-root, no privilege escalation)

---

## 🐛 Troubleshooting

See [**docs/TROUBLESHOOTING.md**](docs/TROUBLESHOOTING.md) for detailed troubleshooting guide.

### Common Issues

<details>
<summary><b>Port 5000 already in use (macOS)</b></summary>

**Issue**: macOS Control Center uses port 5000

**Solution**:
```bash
# Use a different host port
docker run -d -p 8888:5000 devops-portfolio-app:local
# Or update Makefile to use different port
```
</details>

<details>
<summary><b>KIND cluster creation fails</b></summary>

**Issue**: Insufficient Docker resources

**Solution**:
```bash
# Ensure Docker has sufficient resources:
# - CPU: 4+ cores
# - Memory: 8GB+ RAM
# - Disk: 20GB+ free space

# Check Docker Desktop → Settings → Resources

# Delete and recreate cluster
kind delete cluster --name devops-cluster
kind create cluster --config kind/single-node.yaml --name devops-cluster
```
</details>

<details>
<summary><b>ImagePullBackOff in Kubernetes</b></summary>

**Issue**: Pod cannot pull image from local Docker

**Solution**:
```bash
# Load image into KIND cluster
kind load docker-image devops-portfolio-app:local --name devops-cluster

# Or update deployment to use local image
kubectl set image deployment/devops-app app=devops-portfolio-app:local -n devops-app
```
</details>

<details>
<summary><b>Prometheus not scraping metrics</b></summary>

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
</details>

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | System design decisions and patterns |
| [KIND_SETUP.md](docs/KIND_SETUP.md) | KIND installation and cluster setup |
| [CI_CD_GUIDE.md](docs/CI_CD_GUIDE.md) | CI/CD pipeline documentation |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common issues and solutions |
| [PRODUCTION_ENHANCEMENTS.md](docs/PRODUCTION_ENHANCEMENTS.md) | 24 advanced features for learning |
| [AGENTS.md](AGENTS.md) | AI agent context and conventions |

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes**
4. **Run tests** (`make test && make lint`)
5. **Commit your changes** (`git commit -m 'Add amazing feature'`)
6. **Push to the branch** (`git push origin feature/amazing-feature`)
7. **Open a Pull Request**

### Contribution Guidelines

- Follow existing code style (flake8, black)
- Add tests for new features
- Update documentation as needed
- Ensure CI pipeline passes
- Keep commits atomic and well-described

---

## 📖 Learning Resources

### Books
- "Site Reliability Engineering" by Google
- "Kubernetes Patterns" by Bilgin Ibryam
- "Production Kubernetes" by Josh Rosso
- "The DevOps Handbook" by Gene Kim

### Online Courses
- [Kubernetes Fundamentals (CNCF)](https://www.cncf.io/certification/training/)
- [Docker Mastery (Udemy)](https://www.udemy.com/course/docker-mastery/)
- [GitOps Fundamentals (Codefresh)](https://codefresh.io/learn/gitops/)

### Practice Labs
- [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [Istio Workshop](https://istio.io/latest/docs/setup/getting-started/)
- [Prometheus & Grafana Labs](https://prometheus.io/docs/tutorials/getting_started/)

---

## 🌟 Star History

If you find this project helpful, please consider giving it a star! ⭐

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Kubernetes](https://kubernetes.io/) - Container orchestration
- [KIND](https://kind.sigs.k8s.io/) - Kubernetes in Docker
- [Prometheus](https://prometheus.io/) - Monitoring and alerting
- [Grafana](https://grafana.com/) - Observability platform
- [ArgoCD](https://argo-cd.readthedocs.io/) - GitOps continuous delivery
- [Trivy](https://trivy.dev/) - Security scanner

---

## 📞 Contact & Support

- **Issues**: [GitHub Issues](https://github.com/Ramiz-Takildar/devops-portfolio-platform/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Ramiz-Takildar/devops-portfolio-platform/discussions)
- **Email**: [your-email@example.com](mailto:your-email@example.com)

---

<div align="center">

**Built with ❤️ for the DevOps Community**

[⬆ Back to Top](#devops-portfolio-platform)

</div>