# Monitoring & Observability

Prometheus, Grafana, alerting rules, and dashboards for the DevOps Portfolio Platform.

## Structure

| File/Directory | Purpose |
|----------------|---------|
| `prometheus-deployment.yaml` | Prometheus deployment and service |
| `grafana-deployment.yaml` | Grafana deployment and service |
| `servicemonitor.yaml` | Prometheus Operator ServiceMonitor for app metrics |
| `grafana-datasource.yaml` | Grafana datasource configuration |
| `grafana-dashboard-provider.yaml` | Dashboard provisioning config |
| `grafana-dashboards-configmap.yaml` | ConfigMap with dashboard JSON |
| `dashboards/infrastructure.json` | Infrastructure metrics dashboard |
| `dashboards/application.json` | Application metrics dashboard |
| `alert-rules.yaml` | Prometheus alerting rules |

## Installation

```bash
kubectl apply -f monitoring/
```
