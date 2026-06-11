# Kubernetes Manifests

Production-grade Kubernetes manifests for deploying the application to a KIND cluster.

## Files

| File | Purpose |
|------|---------|
| `namespace.yaml` | Namespace definition |
| `configmap.yaml` | Non-sensitive configuration |
| `secret.yaml` | Sensitive data (base64 encoded in practice, use Sealed Secrets or External Secrets in production) |
| `deployment.yaml` | Application deployment with probes, resource limits |
| `service.yaml` | ClusterIP service |
| `ingress.yaml` | Ingress routing |

## Deployment

```bash
kubectl apply -f kubernetes/
```
