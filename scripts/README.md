# Scripts

Helper scripts for local development, CI/CD, and cluster operations.

## Scripts

| Script | Purpose |
|--------|---------|
| `setup-kind.sh` | Bootstrap a local KIND cluster with ingress |
| `deploy.sh` | Deploy application to the cluster |
| `port-forward.sh` | Port-forward Grafana and Prometheus for local access |

## Usage

```bash
chmod +x scripts/*.sh
./scripts/setup-kind.sh
```
