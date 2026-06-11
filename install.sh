#!/bin/bash

################################################################################
# DevOps Portfolio Platform - One-Click Installation Script
################################################################################
# This script automates the complete setup of the DevOps Portfolio Platform
# including prerequisites, KIND cluster, application deployment, and monitoring.
#
# Usage: ./install.sh [OPTIONS]
#
# Options:
#   --skip-prereqs    Skip prerequisite checks and installations
#   --multi-node      Create multi-node cluster (default: single-node)
#   --no-monitoring   Skip monitoring stack deployment
#   --argocd          Install ArgoCD for GitOps (optional)
#   --help            Show this help message
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="devops-cluster"
CLUSTER_TYPE="single"
SKIP_PREREQS=false
SKIP_MONITORING=false
INSTALL_ARGOCD=false
APP_IMAGE="devops-portfolio-app:local"

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_error "$1 is not installed"
        return 1
    fi
}

################################################################################
# Parse Arguments
################################################################################

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-prereqs)
            SKIP_PREREQS=true
            shift
            ;;
        --multi-node)
            CLUSTER_TYPE="multi"
            shift
            ;;
        --no-monitoring)
            SKIP_MONITORING=true
            shift
            ;;
        --argocd)
            INSTALL_ARGOCD=true
            shift
            ;;
        --help)
            grep "^#" "$0" | grep -v "#!/bin/bash" | sed 's/^# //'
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

################################################################################
# Welcome Message
################################################################################

clear
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   DevOps Portfolio Platform - One-Click Installation         ║
║                                                               ║
║   This script will install and configure:                    ║
║   • Docker (if needed)                                        ║
║   • kubectl                                                   ║
║   • KIND                                                      ║
║   • Python dependencies                                       ║
║   • KIND Kubernetes cluster                                   ║
║   • Flask application                                         ║
║   • Prometheus & Grafana monitoring                           ║
║   • ArgoCD for GitOps (optional with --argocd)                ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF

echo ""
print_info "Installation will begin in 3 seconds..."
sleep 3

################################################################################
# Phase 1: Check Prerequisites
################################################################################

if [ "$SKIP_PREREQS" = false ]; then
    print_header "Phase 1: Checking Prerequisites"
    
    MISSING_TOOLS=()
    
    # Check Docker
    if ! check_command docker; then
        MISSING_TOOLS+=("docker")
    else
        # Check Docker is running
        if ! docker info &> /dev/null; then
            print_error "Docker is installed but not running"
            print_info "Please start Docker Desktop and run this script again"
            exit 1
        fi
        
        # Check Docker resources
        DOCKER_CPUS=$(docker info --format '{{.NCPU}}' 2>/dev/null || echo "0")
        DOCKER_MEM=$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo "0")
        DOCKER_MEM_GB=$((DOCKER_MEM / 1024 / 1024 / 1024))
        
        if [ "$DOCKER_CPUS" -lt 4 ]; then
            print_warning "Docker has only $DOCKER_CPUS CPUs (recommended: 4+)"
        fi
        
        if [ "$DOCKER_MEM_GB" -lt 8 ]; then
            print_warning "Docker has only ${DOCKER_MEM_GB}GB RAM (recommended: 8GB+)"
        fi
    fi
    
    # Check kubectl
    if ! check_command kubectl; then
        MISSING_TOOLS+=("kubectl")
    fi
    
    # Check KIND
    if ! check_command kind; then
        MISSING_TOOLS+=("kind")
    fi
    
    # Check Python
    if ! check_command python3; then
        MISSING_TOOLS+=("python3")
    else
        PYTHON_VERSION=$(python3 --version | awk '{print $2}')
        print_success "Python $PYTHON_VERSION is installed"
    fi
    
    # Install missing tools
    if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
        print_warning "Missing tools: ${MISSING_TOOLS[*]}"
        print_info "Attempting to install missing tools..."
        
        # Detect OS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if ! command -v brew &> /dev/null; then
                print_error "Homebrew is not installed. Please install it first:"
                echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                exit 1
            fi
            
            for tool in "${MISSING_TOOLS[@]}"; do
                print_info "Installing $tool via Homebrew..."
                brew install "$tool"
            done
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            print_error "Please install the following tools manually:"
            for tool in "${MISSING_TOOLS[@]}"; do
                echo "  - $tool"
            done
            echo ""
            echo "Installation guides:"
            echo "  Docker: https://docs.docker.com/engine/install/"
            echo "  kubectl: https://kubernetes.io/docs/tasks/tools/"
            echo "  KIND: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
            exit 1
        fi
    fi
    
    print_success "All prerequisites are installed"
else
    print_info "Skipping prerequisite checks"
fi

################################################################################
# Phase 2: Install Python Dependencies
################################################################################

print_header "Phase 2: Installing Python Dependencies"

if [ -f "app/requirements.txt" ]; then
    print_info "Installing Python packages..."
    pip3 install -q -r app/requirements.txt
    pip3 install -q pytest
    print_success "Python dependencies installed"
else
    print_error "app/requirements.txt not found"
    exit 1
fi

################################################################################
# Phase 3: Run Tests
################################################################################

print_header "Phase 3: Running Unit Tests"

cd app
if python3 -m pytest tests/ -v --tb=short; then
    print_success "All tests passed"
else
    print_error "Tests failed"
    exit 1
fi
cd ..

################################################################################
# Phase 4: Build Docker Image
################################################################################

print_header "Phase 4: Building Docker Image"

print_info "Building $APP_IMAGE..."
if docker build -t "$APP_IMAGE" . > /tmp/docker-build.log 2>&1; then
    IMAGE_SIZE=$(docker images "$APP_IMAGE" --format "{{.Size}}")
    print_success "Docker image built successfully (Size: $IMAGE_SIZE)"
else
    print_error "Docker build failed. Check /tmp/docker-build.log for details"
    exit 1
fi

################################################################################
# Phase 5: Create KIND Cluster
################################################################################

print_header "Phase 5: Creating KIND Cluster"

# Check if cluster already exists
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    print_warning "Cluster '$CLUSTER_NAME' already exists"
    read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deleting existing cluster..."
        kind delete cluster --name "$CLUSTER_NAME"
    else
        print_info "Using existing cluster"
        CLUSTER_EXISTS=true
    fi
fi

if [ -z "$CLUSTER_EXISTS" ]; then
    print_info "Creating $CLUSTER_TYPE-node KIND cluster..."
    
    if [ "$CLUSTER_TYPE" = "multi" ]; then
        CONFIG_FILE="kind/multi-node.yaml"
    else
        CONFIG_FILE="kind/single-node.yaml"
    fi
    
    if kind create cluster --config "$CONFIG_FILE" --name "$CLUSTER_NAME"; then
        print_success "KIND cluster created"
    else
        print_error "Failed to create KIND cluster"
        exit 1
    fi
    
    # Wait for cluster to be ready
    print_info "Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=120s
    print_success "Cluster is ready"
fi

################################################################################
# Phase 6: Install NGINX Ingress Controller
################################################################################

print_header "Phase 6: Installing NGINX Ingress Controller"

print_info "Applying NGINX Ingress manifests..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml > /dev/null 2>&1

print_info "Waiting for Ingress Controller to be ready..."
if kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=180s > /dev/null 2>&1; then
    print_success "NGINX Ingress Controller is ready"
else
    print_warning "Ingress Controller took longer than expected, but may still be starting"
fi

################################################################################
# Phase 7: Load Docker Image into KIND
################################################################################

print_header "Phase 7: Loading Docker Image into KIND"

print_info "Loading $APP_IMAGE into KIND cluster..."
if kind load docker-image "$APP_IMAGE" --name "$CLUSTER_NAME"; then
    print_success "Image loaded into cluster"
else
    print_error "Failed to load image"
    exit 1
fi

################################################################################
# Phase 8: Deploy Application
################################################################################

print_header "Phase 8: Deploying Application"

print_info "Applying Kubernetes manifests..."
kubectl apply -f kubernetes/ > /dev/null 2>&1

print_info "Waiting for application pods to be ready..."
if kubectl wait --for=condition=ready pod \
    -l app=devops-app \
    -n devops-app \
    --timeout=120s > /dev/null 2>&1; then
    print_success "Application deployed successfully"
else
    print_error "Application deployment timed out"
    kubectl get pods -n devops-app
    exit 1
fi

# Get pod status
POD_COUNT=$(kubectl get pods -n devops-app -l app=devops-app --no-headers | wc -l | tr -d ' ')
print_info "Running pods: $POD_COUNT"

################################################################################
# Phase 9: Deploy Monitoring Stack
################################################################################

if [ "$SKIP_MONITORING" = false ]; then
    print_header "Phase 9: Deploying Monitoring Stack"
    
    print_info "Applying monitoring manifests..."
    kubectl apply -f monitoring/ > /dev/null 2>&1
    
    print_info "Waiting for Prometheus to be ready..."
    kubectl wait --for=condition=ready pod \
        -l app=prometheus \
        -n monitoring \
        --timeout=120s > /dev/null 2>&1 || true
    
    print_info "Waiting for Grafana to be ready..."
    kubectl wait --for=condition=ready pod \
        -l app=grafana \
        -n monitoring \
        --timeout=120s > /dev/null 2>&1 || true
    
    print_success "Monitoring stack deployed"
else
    print_info "Skipping monitoring stack deployment"
fi

################################################################################
# Phase 10: Deploy ArgoCD (Optional)
################################################################################

if [ "$INSTALL_ARGOCD" = true ]; then
    print_header "Phase 10: Deploying ArgoCD for GitOps"
    
    print_info "Installing ArgoCD..."
    cd argocd
    chmod +x install.sh
    if ./install.sh > /tmp/argocd-install.log 2>&1; then
        print_success "ArgoCD installed successfully"
        
        print_info "Getting ArgoCD admin password..."
        ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)
        
        if [ -n "$ARGOCD_PASSWORD" ]; then
            print_success "ArgoCD admin password retrieved"
            echo "$ARGOCD_PASSWORD" > /tmp/argocd-admin-password.txt
            print_info "Password saved to /tmp/argocd-admin-password.txt"
        fi
    else
        print_warning "ArgoCD installation encountered issues. Check /tmp/argocd-install.log"
    fi
    cd ..
else
    print_info "Skipping ArgoCD installation (use --argocd to enable)"
fi

################################################################################
# Phase 11: Verification
################################################################################

print_header "Phase 11: Verification"

print_info "Verifying deployment..."

# Check namespaces
NAMESPACES=$(kubectl get namespaces --no-headers | awk '{print $1}' | grep -E 'devops-app|monitoring' | wc -l | tr -d ' ')
print_success "Namespaces created: $NAMESPACES"

# Check deployments
DEPLOYMENTS=$(kubectl get deployments -n devops-app --no-headers | wc -l | tr -d ' ')
print_success "Deployments in devops-app: $DEPLOYMENTS"

# Check services
SERVICES=$(kubectl get services -n devops-app --no-headers | wc -l | tr -d ' ')
print_success "Services in devops-app: $SERVICES"

################################################################################
# Installation Complete
################################################################################

print_header "Installation Complete! 🎉"

cat << EOF

${GREEN}✓ Installation completed successfully!${NC}

${BLUE}Quick Access Commands:${NC}

  ${YELLOW}# Access Application${NC}
  kubectl port-forward svc/devops-app 8080:80 -n devops-app
  curl http://localhost:8080/health

  ${YELLOW}# Access Grafana (admin/admin)${NC}
  kubectl port-forward svc/grafana 3000:3000 -n monitoring
  open http://localhost:3000

  ${YELLOW}# Access Prometheus${NC}
  kubectl port-forward svc/prometheus 9090:9090 -n monitoring
  open http://localhost:9090
EOF

if [ "$INSTALL_ARGOCD" = true ]; then
    cat << EOF

  ${YELLOW}# Access ArgoCD (admin / see password below)${NC}
  kubectl port-forward svc/argocd-server 8443:443 -n argocd
  open https://localhost:8443
  
  ${YELLOW}# ArgoCD Admin Password:${NC}
  $(cat /tmp/argocd-admin-password.txt 2>/dev/null || echo "Run: kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d")

EOF
fi

cat << EOF
  ${YELLOW}# View Application Logs${NC}
  kubectl logs -n devops-app -l app=devops-app --tail=50 -f

  ${YELLOW}# View All Resources${NC}
  kubectl get all -n devops-app
  kubectl get all -n monitoring

${BLUE}Cluster Information:${NC}
  Cluster Name: ${CLUSTER_NAME}
  Cluster Type: ${CLUSTER_TYPE}-node
  Nodes: $(kubectl get nodes --no-headers | wc -l | tr -d ' ')

${BLUE}Next Steps:${NC}
  1. Port-forward the application service
  2. Test the endpoints (/, /health, /ready, /metrics, /version)
  3. Access Grafana dashboards
  4. Review Prometheus metrics
  5. Check the documentation in docs/ directory

${BLUE}Useful Commands:${NC}
  make help              # Show all available make commands
  kubectl get pods -A    # List all pods in all namespaces
  kind delete cluster    # Delete the cluster when done

${GREEN}Happy DevOps-ing! 🚀${NC}

EOF

# Save installation info
cat > /tmp/devops-install-info.txt << EOF
Installation completed at: $(date)
Cluster Name: ${CLUSTER_NAME}
Cluster Type: ${CLUSTER_TYPE}-node
Application Image: ${APP_IMAGE}
Monitoring: $([ "$SKIP_MONITORING" = false ] && echo "Enabled" || echo "Disabled")
EOF

print_info "Installation details saved to /tmp/devops-install-info.txt"
