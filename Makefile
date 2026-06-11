# ---------------------------------------------------------------------------
# DevOps Portfolio Platform — Makefile
# ---------------------------------------------------------------------------

.PHONY: help build run test lint clean deploy-local kind-up kind-down

APP_NAME ?= devops-portfolio-app
IMAGE_TAG ?= local
REGISTRY ?= ghcr.io/yourusername
NAMESPACE ?= devops-app

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ---------------------------------------------------------------------------
# Docker
# ---------------------------------------------------------------------------

build: ## Build Docker image locally
	docker build -t $(APP_NAME):$(IMAGE_TAG) .

run: ## Run Docker container locally
	docker run -d --name $(APP_NAME) -p 5000:5000 $(APP_NAME):$(IMAGE_TAG)

stop: ## Stop running container
	docker stop $(APP_NAME) || true
	docker rm $(APP_NAME) || true

# ---------------------------------------------------------------------------
# Testing
# ---------------------------------------------------------------------------

test: ## Run unit tests
	cd app && python -m pytest tests/ -v

lint: ## Run flake8 linting
	cd app && flake8 main.py tests/

# ---------------------------------------------------------------------------
# Kubernetes (Local KIND)
# ---------------------------------------------------------------------------

kind-up: ## Create KIND cluster
	./scripts/setup-kind.sh

kind-down: ## Delete KIND cluster
	kind delete cluster --name devops-cluster

deploy-local: ## Deploy to local KIND cluster
	kubectl apply -f kubernetes/
	kubectl rollout status deployment/devops-app -n $(NAMESPACE)

port-forward: ## Port-forward services for local access
	kubectl port-forward svc/grafana 3000:3000 -n monitoring &
	kubectl port-forward svc/prometheus 9090:9090 -n monitoring &

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

clean: ## Remove containers, images, and build artifacts
	docker stop $(APP_NAME) || true
	docker rm $(APP_NAME) || true
	docker rmi $(APP_NAME):$(IMAGE_TAG) || true
