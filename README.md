# CD-010 · GitHub Actions Advanced CI/CD

[![CI](https://github.com/BHAVISHYA-RAJ-14/cd-010-github-actions-cicd/actions/workflows/ci.yml/badge.svg)](https://github.com/BHAVISHYA-RAJ-14/cd-010-github-actions-cicd/actions/workflows/ci.yml)
[![Matrix Tests](https://github.com/BHAVISHYA-RAJ-14/cd-010-github-actions-cicd/actions/workflows/matrix-test.yml/badge.svg)](https://github.com/BHAVISHYA-RAJ-14/cd-010-github-actions-cicd/actions/workflows/matrix-test.yml)
[![Release](https://github.com/BHAVISHYA-RAJ-14/cd-010-github-actions-cicd/actions/workflows/release.yml/badge.svg)](https://github.com/BHAVISHYA-RAJ-14/cd-010-github-actions-cicd/actions/workflows/release.yml)
[![Python 3.12](https://img.shields.io/badge/Python-3.11%20%7C%203.12-blue?logo=python)](https://python.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)

> **Production-grade GitHub Actions CI/CD platform** — reusable workflows, OIDC keyless AWS auth, 3D matrix builds, deployment environments with approval gates, full release automation pipeline, and self-hosted runners on Kubernetes (ARC). Built as part of the Next Afield Cloud & DevOps internship (Intern ID: NAI26MAR-CD-01).

---

## 🏗️ Architecture

```
Developer Push / Tag
        │
        ▼
┌─────────────────────────────────────────────────────────────┐
│                  GitHub Actions Workflows                    │
│                                                             │
│  ci.yml          → PR: lint + unit test + Trivy scan        │
│  matrix-test.yml → 3D matrix: 2 OS × 2 Python × 2 PG = 8  │
│  deploy.yml      → push main: staging → soak → prod         │
│  release.yml     → tag v*.*.*: Docker + Helm + PyPI + GH    │
│  reusable-*.yml  → called by all above (5+ workflows)       │
└─────────────────────────────────────────────────────────────┘
        │                       │
        ▼                       ▼
  AWS (OIDC)              ECR Registry
  keyless auth            amd64 + arm64
  no stored keys          Docker images
        │
  GitHub Environments
  staging (auto) → 15min soak → production (2 approvals)
        │
  Self-Hosted Runners
  ARC on Kubernetes
  ephemeral + autoscaling
```

---

## ✅ Deliverables (8/8)

| # | Deliverable | Location |
|---|---|---|
| 1 | Reusable workflow library (5+ workflows) | `.github/workflows/reusable-*.yml` |
| 2 | OIDC keyless AWS authentication | `terraform/oidc-role/` |
| 3 | Matrix builds (3 dimensions, 8 jobs) | `.github/workflows/matrix-test.yml` |
| 4 | GitHub Environments with approval gates | `deploy.yml` + repo settings |
| 5 | Release automation pipeline (Docker + Helm + PyPI) | `.github/workflows/release.yml` |
| 6 | Self-hosted runners on Kubernetes (ARC) | `arc/runner-deployment.yaml` |
| 7 | CHANGELOG auto-generation | `cliff.toml` + release workflow |
| 8 | Multi-arch Docker build (amd64 + arm64) | `.github/actions/docker-build/` |

---

## 🚀 Quick Start

### Prerequisites
```bash
git --version          # 2.40+
docker --version       # 24+
python3 --version      # 3.11 or 3.12
aws --version          # v2
terraform --version    # 1.7+
helm version           # 3.x
```

### 1. Clone & Install
```bash
git clone https://github.com/BHAVISHYA-RAJ-14/cd-010-github-actions-cicd.git
cd cd-010-github-actions-cicd
make install
```

### 2. Run Locally
```bash
make run
# → http://localhost:8000
# → http://localhost:8000/docs (Swagger UI)
# → http://localhost:8000/health
```

### 3. Run Tests
```bash
make test
make test-cov   # with coverage report
```

### 4. Set Up OIDC (one-time)
```bash
make terraform-init
make terraform-plan
make terraform-apply
# → Outputs: AWS_ROLE_ARN_DEV and AWS_ROLE_ARN_PROD
# → Add these as GitHub repo secrets
```

### 5. Trigger Release Pipeline
```bash
make release-tag V=v1.0.0
# → Pushes tag → triggers release.yml
# → Builds Docker (amd64+arm64) → ECR
# → Generates CHANGELOG → GitHub Release
# → Publishes Python wheel → TestPyPI
```

---

## 📁 Project Structure

```
cd-010-github-actions-cicd/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                     # PR: lint + test + scan
│   │   ├── deploy.yml                 # Push main: staging → prod
│   │   ├── release.yml                # Tag v*: full release pipeline
│   │   ├── matrix-test.yml            # 3D matrix (8 jobs)
│   │   ├── reusable-docker-build.yml  # Reusable: multi-arch Docker
│   │   ├── reusable-deploy-k8s.yml    # Reusable: Helm deploy
│   │   └── reusable-notify.yml        # Reusable: Slack notification
│   ├── actions/
│   │   ├── setup-python/action.yml    # Composite: install + cache + lint
│   │   ├── docker-build/action.yml    # Composite: buildx + ECR push
│   │   └── notify-slack/action.yml    # Composite: Slack block-kit
│   └── dependabot.yml                 # Auto action/dep updates
├── src/app/main.py                    # FastAPI sample app
├── tests/unit/test_main.py            # Pytest unit tests
├── helm/cd010-app/                    # Helm chart for K8s deploy
├── arc/runner-deployment.yaml         # ARC self-hosted K8s runners
├── terraform/oidc-role/               # IAM OIDC role (no stored keys)
├── cliff.toml                         # CHANGELOG config (git-cliff)
├── Dockerfile                         # Multi-stage, non-root, arm64-ready
├── Makefile                           # All commands
└── pyproject.toml                     # Python project config
```

---

## 🔒 OIDC Keyless Authentication

```
GitHub Actions Job
       │
       │  1. Request JWT from GitHub OIDC
       ▼
GitHub OIDC Provider (token.actions.githubusercontent.com)
       │
       │  2. Exchange JWT for AWS temp credentials
       ▼
AWS STS AssumeRoleWithWebIdentity
       │
       │  3. 1-hour credentials (auto-expire)
       ▼
IAM Role (cd010-github-actions-dev/prod)
       │
       │  No access keys stored. Ever.
       ▼
ECR / EKS / CloudFormation
```

---

## 🧪 Matrix Build Strategy

| Dimension | Values | Count |
|---|---|---|
| OS | ubuntu-22.04, ubuntu-24.04 | 2 |
| Python | 3.11, 3.12 | 2 |
| Postgres | 15, 16 | 2 |
| **Total jobs** | | **8** (after 0 exclusions) |
| `fail-fast` | false | all legs always run |
| Target CI time | | < 5 minutes |

---

## 🛠️ Tech Stack

![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-CI%2FCD-black?logo=githubactions)
![Docker](https://img.shields.io/badge/Docker-Buildx%20Multi--Arch-blue?logo=docker)
![Kubernetes](https://img.shields.io/badge/Kubernetes-ARC%20Runners-blue?logo=kubernetes)
![AWS](https://img.shields.io/badge/AWS-OIDC%20%7C%20ECR-orange?logo=amazonaws)
![Terraform](https://img.shields.io/badge/Terraform-OIDC%20Role-purple?logo=terraform)
![Helm](https://img.shields.io/badge/Helm-3.x-blue?logo=helm)
![Trivy](https://img.shields.io/badge/Trivy-Security%20Scan-red)
![git-cliff](https://img.shields.io/badge/git--cliff-CHANGELOG-green)

---

## 👤 Author

**Bhavishya Raj** · Cloud & DevOps Intern · NAI26MAR-CD-01 · Next Afield
AWS Student Builder Group Leader · GLA University

[![GitHub](https://img.shields.io/badge/GitHub-BHAVISHYA--RAJ--14-black?logo=github)](https://github.com/BHAVISHYA-RAJ-14)

# test PR flow
