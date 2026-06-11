# System Architecture

## Design Goals

1. **Portfolio Quality**: Every file should reflect enterprise-grade DevOps practices
2. **Local First**: Everything runs on a local machine using Docker and KIND
3. **Production Patterns**: Use the same patterns as real cloud deployments
4. **Observability**: Metrics, logs, and dashboards out of the box
5. **Security**: Defense in depth at every layer

## Layered Architecture

### Layer 1: Application

The Flask application follows the 12-Factor App methodology:

- **Codebase**: Single repo for app + infrastructure
- **Dependencies**: Pinned in requirements.txt
- **Config**: Environment variables via ConfigMap
- **Backing Services**: None (stateless design)
- **Build/Release/Run**: Strict separation via multi-stage Docker
- **Processes**: Stateless, shared-nothing processes (gunicorn workers)
- **Port Binding**: Self-contained HTTP server on port 5000
- **Concurrency**: Process model via gunicorn (2 workers, 4 threads)
- **Disposability**: Fast startup (5s) and graceful shutdown (30s)
- **Dev/Prod Parity**: Same Docker image in all environments
- **Logs**: Structured JSON to stdout (12-factor compliant)
- **Admin Processes**: No admin tasks; health endpoints provide ops data

### Layer 2: Containerization

Multi-stage Dockerfile design:

```
Builder Stage:
  - python:3.12-alpine
  - Install build dependencies (gcc, musl-dev)
  - Compile Python dependencies into venv
  - Maximum layer caching (requirements copied before app code)

Runtime Stage:
  - python:3.12-alpine (no build tools)
  - Copy venv from builder
  - Copy app code
  - Set non-root user (uid 1000)
  - Add security headers and HEALTHCHECK
  - Run gunicorn (not Flask dev server)
```

Security posture:
- Non-root execution
- Read-only root filesystem (Prometheus/Grafana)
- No privilege escalation
- Dropped Linux capabilities
- Minimized attack surface (alpine base)

### Layer 3: CI/CD Pipeline

Split workflow design:

**CI (Fast Feedback)**:
- Parallel jobs: lint, test, security
- Uses pip caching for speed
- Runs on every PR (cancel previous runs via concurrency)
- Does NOT build Docker (fast feedback)

**CD (Slow, Expensive)**:
- Multi-arch Docker build (QEMU emulation)
- Trivy image scan
- GHCR publish
- ArgoCD GitOps sync (local KIND cluster)
- Runs only on main branch and tags

Branch protection:
- Requires CI to pass before merge
- PR review required
- Up-to-date branch enforcement

### Layer 4: Kubernetes

Resource model:

```
Namespace: devops-app
├── ConfigMap: app configuration (non-sensitive)
├── Secret: sensitive data (demo values only)
├── Deployment: 2 replicas, RollingUpdate
│   ├── SecurityContext: runAsNonRoot, seccomp
│   ├── Resources: requests + limits
│   ├── Probes: liveness, readiness, startup
│   └── Annotations: prometheus.io/scrape
├── Service: ClusterIP, port 80 → 5000
├── Ingress: NGINX, host-based routing

```

Deployment strategy:
- RollingUpdate with maxUnavailable: 0 (zero-downtime)
- maxSurge: 1 (gradual rollout)
- Startup probe prevents premature liveness failures
- Resource limits prevent noisy neighbors

### Layer 5: Observability

Three pillars implemented:

**Metrics**:
- Application metrics via prometheus-client (request count, latency, errors)
- Cluster metrics via kubelet/cAdvisor (CPU, memory, pod status)
- Custom business metrics (version endpoint)

**Logs**:
- Structured JSON logging to stdout
- Every log line includes timestamp, level, app name, version
- Kubernetes captures stdout automatically

**Dashboards**:
- Infrastructure: CPU, memory, pod status, restarts, cluster health
- Application: Request rate, error rate, latency percentiles
- Provisioned via ConfigMap (GitOps-friendly)

## Data Flow

```
User Request
    |
    v
Ingress (NGINX) → Service (ClusterIP) → Pod (Flask)
    |                                              |
    |                                              v
    |                                      Prometheus Metrics
    |                                              |
    |                                              v
    |                                      Prometheus Server
    |                                              |
    v                                              v
Grafana Dashboards ← Querying ← Prometheus Data
```

## Security Model

| Layer | Control | Implementation |
|-------|---------|---------------|
| Code | Linting | flake8, black |
| Dependencies | Vulnerability scanning | Trivy FS scan |
| Image | Non-root container | USER 1000, alpine base |
| Image | Minimal attack surface | Multi-stage build, no build tools |
| Image | Vulnerability scanning | Trivy image scan |
| Container | Runtime security | allowPrivilegeEscalation: false |
| Container | Capability dropping | drop ALL |
| Container | Seccomp | RuntimeDefault |
| Network | Service mesh ready | Istio/Linkerd in production |
| Kubernetes | RBAC | Least privilege for Prometheus |
| Secrets | Management | Sealed Secrets / External Secrets Operator |

## Scalability Considerations

Current limits:
- Single-node KIND cluster: ~4-8 pods depending on resources
- Multi-node KIND cluster: ~12-20 pods across nodes
- Replica count: 2 (can be increased in deployment.yaml)

Production scaling path:
- Replace KIND with EKS/GKE/AKS
- Use Cluster Autoscaler for node scaling
- Use Vertical Pod Autoscaler for right-sizing
- Replace emptyDir with SSD-backed PVCs
- Use Redis/external cache for session state

## Technology Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Language | Python Flask | Simple, readable, fast to develop |
| Base Image | python:3.12-alpine | Smallest secure Python image (~20MB base) |
| WSGI | gunicorn | Production-grade, threaded workers |
| Metrics | prometheus-client | De facto standard for K8s metrics |
| CI/CD | GitHub Actions | Native integration, free for public repos |
| Registry | GHCR | No extra credentials, integrated with Actions |
| K8s Distribution | KIND | Runs in Docker, perfect for local dev |
| Monitoring | Prometheus + Grafana | Industry standard stack |
| Ingress | NGINX | Most widely used K8s ingress controller |
| Security Scanner | Trivy | Comprehensive, easy to integrate |
