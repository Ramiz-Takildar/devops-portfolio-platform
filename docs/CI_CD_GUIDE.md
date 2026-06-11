# CI/CD Guide

## Overview

The DevOps Portfolio Platform uses GitHub Actions for continuous integration and continuous deployment. The pipeline is split into two workflows to separate fast feedback (CI) from slower, more expensive operations (CD).

## Workflows

### `ci.yml` — Continuous Integration

**Triggers**: Push/PR to `main` or `develop`

| Job | Purpose | Tools |
|-----|---------|-------|
| `lint` | Code quality and formatting | flake8, black |
| `test` | Unit test execution | pytest |
| `security-scan` | Vulnerability detection | Trivy (filesystem) |

**Key Features**:
- Pip caching via `actions/setup-python` cache
- Concurrency control (cancel in-progress runs)
- Path ignores for markdown/documentation changes
- Artifact upload for test results
- SARIF upload to GitHub Security tab

### `cd.yml` — Continuous Deployment

**Triggers**: Push to `main`, tags `v*.*.*`

| Job | Purpose | Tools |
|-----|---------|-------|
| `build-and-push` | Multi-arch image build and registry push | docker/build-push-action, docker/metadata-action |
| `deploy-validation` | KIND cluster validation | helm/kind-action, kubectl |

**Key Features**:
- Multi-architecture builds (AMD64 + ARM64)
- GitHub Container Registry (GHCR) publishing
- Semantic versioning via docker/metadata-action
- Image vulnerability scanning before push
- SBOM generation (SPDX format)
- KIND-based smoke tests post-build

## Required Secrets

No additional secrets are required beyond the automatically provided `GITHUB_TOKEN`. Ensure the following permissions are set:

- **Packages**: Write (for GHCR publishing)
- **Security events**: Write (for SARIF uploads)

Configure this at **Settings → Actions → General → Workflow permissions**.

## Branch Protection Strategy

For production-grade repository management, configure branch protection on `main`:

1. Require PR reviews before merging (1+ reviewer)
2. Require status checks to pass:
   - `Lint`
   - `Unit Tests`
   - `Security Scan`
3. Require branches to be up to date before merging
4. Restrict pushes that create files larger than 100MB
5. Enable "Include administrators"

## Semantic Versioning

Tags follow [SemVer](https://semver.org/):

```bash
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin --tags
```

The CD workflow automatically generates:
- `ghcr.io/owner/repo:1.2.3`
- `ghcr.io/owner/repo:1.2`
- `ghcr.io/owner/repo:1`
- `ghcr.io/owner/repo:latest` (on default branch only)

## Local Testing

Run the same checks locally before pushing:

```bash
# Linting
cd app && flake8 main.py tests/ --max-line-length=120

# Tests
python -m pytest tests/ -v

# Trivy filesystem scan (requires Trivy CLI)
trivy fs --severity CRITICAL,HIGH .

# Docker build
docker build -t devops-app:local .

# Trivy image scan
trivy image --severity CRITICAL,HIGH devops-app:local
```
