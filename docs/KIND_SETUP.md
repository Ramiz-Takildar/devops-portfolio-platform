# KIND Cluster Setup Guide

## Overview

KIND (Kubernetes IN Docker) runs Kubernetes clusters using Docker containers as nodes. This guide covers installation, cluster creation, and verification for the DevOps Portfolio Platform.

## Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Docker | 24.0+ | Container runtime |
| kubectl | 1.30+ | Kubernetes CLI |
| KIND | 0.23+ | Local cluster provisioning |

### Install kubectl

**macOS (Homebrew)**:
```bash
brew install kubectl
```

**Linux**:
```bash
curl -LO "https://dl.k8s/release/$(curl -L -s https://dl.k8s/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

**Verify**:
```bash
kubectl version --client
```

### Install KIND

**macOS (Homebrew)**:
```bash
brew install kind
```

**Linux**:
```bash
curl -Lo kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
chmod +x kind
sudo mv kind /usr/local/bin/
```

**Verify**:
```bash
kind version
```

## Kubernetes Architecture Components

### Control Plane

- **API Server** (`kube-apiserver`): Front-end for the Kubernetes API. Validates and configures data for API objects (pods, services, etc.).
- **etcd**: Distributed key-value store that persists cluster state, configuration, and metadata.
- **Scheduler** (`kube-scheduler`): Watches for newly created pods and assigns them to nodes based on resource availability and constraints.
- **Controller Manager** (`kube-controller-manager`): Runs controllers that regulate cluster state (replication, endpoints, namespace, service accounts).
- **Cloud Controller Manager**: Integrates with underlying cloud provider (not needed for KIND).

### Worker Nodes

- **kubelet**: Agent running on each node. Ensures containers are running in a pod and reports node status.
- **kube-proxy**: Network proxy maintaining network rules on nodes. Implements Kubernetes Services via iptables or IPVS.
- **Container Runtime**: Software responsible for running containers. KIND uses containerd (via Docker).

## Cluster Configuration

### Single-Node Cluster (Development)

Best for local development and CI/CD validation. The control-plane node also schedules workloads.

```bash
kind create cluster --config kind/single-node.yaml
```

**Characteristics**:
- 1 control-plane node
- All components on a single Docker container
- Faster startup
- Lower resource usage

### Multi-Node Cluster (Production Simulation)

Best for testing node affinity, pod placement, and resource scheduling.

```bash
kind create cluster --config kind/multi-node.yaml
```

**Characteristics**:
- 1 control-plane node + 2 worker nodes
- Worker nodes labeled `tier=frontend` and `tier=backend`
- Simulates production topology
- Tests node selectors and anti-affinity rules

## Helper Script

Use the provided script for automated setup:

```bash
chmod +x scripts/setup-kind.sh
./scripts/setup-kind.sh
```

This script:
1. Checks prerequisites
2. Creates the cluster
3. Installs NGINX Ingress Controller
4. Verifies node readiness
5. Displays cluster info

## Verification

### Check Cluster Info

```bash
kubectl cluster-info
```

Expected output:
```
Kubernetes control plane is running at https://127.0.0.1:6443
CoreDNS is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

### List Nodes

```bash
kubectl get nodes -o wide
```

Expected output (single-node):
```
NAME                          STATUS   ROLES           AGE   VERSION
devops-cluster-control-plane  Ready    control-plane   2m    v1.30.0
```

Expected output (multi-node):
```
NAME                          STATUS   ROLES           AGE   VERSION
devops-cluster-control-plane  Ready    control-plane   2m    v1.30.0
devops-cluster-worker         Ready    <none>          2m    v1.30.0
devops-cluster-worker2        Ready    <none>          2m    v1.30.0
```

### List System Pods

```bash
kubectl get pods -n kube-system
```

### Describe a Node

```bash
kubectl describe node devops-cluster-control-plane
```

## Ingress Setup

After creating the cluster, install the NGINX Ingress Controller:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

## Common Commands

| Command | Description |
|---------|-------------|
| `kind create cluster --config kind/single-node.yaml` | Create single-node cluster |
| `kind create cluster --config kind/multi-node.yaml` | Create multi-node cluster |
| `kind get clusters` | List all clusters |
| `kind delete cluster --name devops-cluster` | Delete cluster |
| `kind load docker-image <image> --name devops-cluster` | Load local image into cluster |
| `kubectl config use-context kind-devops-cluster` | Switch to cluster context |

## Troubleshooting

### Port Already in Use

If ports 80/443 are in use, modify the `hostPort` values in the KIND config:
```yaml
extraPortMappings:
  - containerPort: 80
    hostPort: 8080
```

### Docker Resource Limits

Ensure Docker has at least:
- **CPU**: 4 cores
- **Memory**: 8 GB
- **Disk**: 20 GB

### Nodes Not Ready

```bash
kubectl describe node <node-name>
kubectl logs -n kube-system <kubelet-pod>
```

### Context Issues

```bash
kubectl config get-contexts
kubectl config use-context kind-devops-cluster
```

## Next Steps

After the cluster is running:
1. [Deploy the application](../kubernetes/README.md)
2. [Install monitoring stack](../monitoring/README.md)
3. [Validate endpoints](../README.md#endpoints)
