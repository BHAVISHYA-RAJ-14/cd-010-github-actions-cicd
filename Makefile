# ─────────────────────────────────────────────────────────────────────────────
# CD-010 GitHub Actions Advanced CI/CD — Makefile
# ─────────────────────────────────────────────────────────────────────────────
.PHONY: help install build run test lint clean docker-build docker-run \
        terraform-init terraform-plan terraform-apply arc-setup release-tag

# ─────────────────────────────────────────────────────────────────────────────
help: ## Show all commands
	 @grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS=":.*?## "}; {printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2}'

# ─────────────────────────────────────────────────────────────────────────────
install: ## Install all dependencies
	pip install -r requirements.txt -r requirements-dev.txt

run: ## Run app locally on port 8000
	ENVIRONMENT=development uvicorn src.app.main:app --host 0.0.0.0 --port 8000 --reload

test: ## Run unit tests
	pytest tests/unit/ -v --tb=short

test-cov: ## Run tests with coverage report
	pytest tests/unit/ --cov=src --cov-report=html --cov-report=term

lint: ## Lint + type check
	flake8 src/ --max-line-length=120 --ignore=E501,W503
	mypy src/ --ignore-missing-imports
	black src/ tests/ --check --diff

format: ## Auto-format with black
	black src/ tests/

# ─────────────────────────────────────────────────────────────────────────────
docker-build: ## Build Docker image locally
	docker build -t cd010-app:local .

docker-run: docker-build ## Run Docker container locally
	docker run -p 8000:8000 --rm cd010-app:local

docker-scan: docker-build ## Scan image with Trivy
	trivy image cd010-app:local

docker-buildx: ## Build multi-arch image (amd64 + arm64) locally
	docker buildx build \
		--platform linux/amd64,linux/arm64 \
		-t cd010-app:multiarch \
		--load \
		.

# ─────────────────────────────────────────────────────────────────────────────
terraform-init: ## Init Terraform OIDC role
	cd terraform/oidc-role && terraform init

terraform-plan: ## Plan OIDC role changes
	cd terraform/oidc-role && terraform plan

terraform-apply: ## Apply OIDC role (creates IAM role + OIDC provider)
	cd terraform/oidc-role && terraform apply

# ─────────────────────────────────────────────────────────────────────────────
arc-setup: ## Install ARC on local k3s/minikube cluster
	 @echo "Installing Actions Runner Controller..."
	helm repo add actions-runner-controller \
		https://actions-runner-controller.github.io/actions-runner-controller
	helm repo update
	helm install arc actions-runner-controller/actions-runner-controller \
		--namespace arc-system \
		--create-namespace \
		--wait
	kubectl apply -f arc/runner-deployment.yaml
	kubectl get pods -n arc-runners

# ─────────────────────────────────────────────────────────────────────────────
release-tag: ## Create and push release tag (usage: make release-tag V=v1.0.0)
	 @if [ -z "$(V)" ]; then echo "Usage: make release-tag V=v1.0.0"; exit 1; fi
	git tag -a $(V) -m "Release $(V)"
	git push origin $(V)
	 @echo "✅ Tag $(V) pushed — release workflow triggered"

changelog-preview: ## Preview CHANGELOG for current HEAD
	git-cliff --config cliff.toml --unreleased

# ─────────────────────────────────────────────────────────────────────────────
clean: ## Remove build artifacts
	rm -rf dist/ build/ .pytest_cache/ htmlcov/ .coverage coverage.xml
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.pyc" -delete 2>/dev/null || true
