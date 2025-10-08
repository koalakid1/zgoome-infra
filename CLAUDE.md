# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 📋 프로젝트 정보

**프로젝트명:** zgoome-infra
**설명:** Kubernetes infrastructure repository for zgoome project using ArgoCD GitOps
**기술 스택:** Kubernetes, ArgoCD, Helm, Sealed Secrets, Prometheus Stack, Grafana, Loki

---

## 🏷️ 프로세스별 필수 참고 문서

작업 시 태그를 사용하면 관련 문서를 자동으로 참조합니다.

### [개발 노트]
- `.claude/info/dev-notes.md` - 알아두면 좋은 것들 (선택적)

> 💡 **dev-notes.md 활용:**
>
> 이 파일은 선택적으로 사용합니다:
> - 코드만으로 알기 어려운 정보
> - ADR (Architecture Decision Record)
> - 트러블슈팅 가이드
> - 개발 팁
>
> `/init`이 분석할 수 있는 정보는 CLAUDE.md에 자동으로 포함되므로 별도 관리 불필요

<!--
프로젝트별 태그를 여기에 추가하세요.

예시:
### [ArgoCD]
- `.claude/info/argocd-guide.md` - ArgoCD 운영 가이드

### [Secrets]
- `.claude/info/secrets-management.md` - Sealed Secrets 관리
-->

---

## Overview

This is a Kubernetes infrastructure repository for the zgoome project, using **ArgoCD** for GitOps-based deployment management. The repository follows a declarative infrastructure-as-code approach where all Kubernetes resources are version-controlled and automatically synchronized to the cluster.

## Architecture

### GitOps with ArgoCD

The repository uses **App of Apps** pattern with ArgoCD:

- **Root Application**: `argocd/root-app.yaml` monitors `argocd/applications/` directory and automatically creates child applications
- **Application Structure**: Applications are organized by category (system, monitoring, db, movie)
- **Sync Waves**: Applications use `argocd.argoproj.io/sync-wave` annotations to control deployment order:
  - `-1`: System components (sealed-secrets, secrets) - deployed first
  - `0`: Core infrastructure (prometheus-stack, loki)
  - `1`: Databases and ingress (postgres, traefik)
  - `2`: Applications (movie-api, movie-ui)

### Directory Structure

```
.
├── argocd/
│   ├── root-app.yaml                    # Root ArgoCD application (App of Apps)
│   └── applications/                     # Child applications
│       ├── system/                       # System-level (sealed-secrets)
│       ├── monitoring/                   # Monitoring stack (prometheus, loki, promtail, grafana)
│       ├── db/                          # Databases (postgres)
│       ├── movie/                       # Movie application (dev/prod for api/ui)
│       ├── ingress.yaml                 # Traefik ingress controller
│       └── secrets.yaml                 # Sealed secrets deployment
├── manifests/                           # Raw Kubernetes manifests
│   ├── db/postgres/                     # PostgreSQL StatefulSet, Service, Backup
│   ├── secrets/                         # Sealed secrets (encrypted)
│   └── ingress/                         # Ingress resources
├── values/                              # Helm chart values files
│   ├── prometheus-values.yaml
│   ├── loki-values.yaml
│   └── promtail-values.yaml
└── scripts/                             # Automation scripts
    └── create-sealed-secret.sh          # Sealed secret generator
```

### Application Patterns

**Helm-based Applications** (with values from this repo):
- Use `sources` array with two entries:
  - Helm chart from upstream repository
  - Values file from this repository (via SSH: `git@github.com:zgoome/zgoome-infra.git`)
- Examples: prometheus-stack, loki, promtail

**Manifest-based Applications**:
- Point directly to manifest directories in this repository
- Examples: postgres, ingress, secrets

**External Applications**:
- Reference manifests from other repositories
- Examples: movie-api, movie-ui (from `zgoome/movie-backend` and `zgoome/movie-frontend` repositories)

### Secrets Management

Uses **Bitnami Sealed Secrets** for secure secret storage in Git:

- Sealed Secrets Controller runs in `kube-system` namespace
- Encrypted secrets stored in `manifests/secrets/` with naming convention: `sealed-{SECRET_NAME}-{NAMESPACE}.yaml`
- Three scope options:
  - `namespace-wide` (recommended): Secret can only be unsealed in specific namespace
  - `strict`: Tied to specific name and namespace
  - `cluster-wide`: Can be unsealed anywhere in cluster

### Monitoring Stack

**Complete observability setup**:
- **Prometheus Stack**: Metrics collection, alerting (15d retention, 8GB limit)
- **Grafana**: Visualization with pre-configured datasources (Prometheus, Loki)
  - Accessible at `grafana.zgoo.me` with TLS
  - Admin credentials from sealed secret `grafana-admin`
- **Loki**: Log aggregation
- **Promtail**: Log collection agent

### Repository References

- **Infrastructure repo** (this repo): `zgoome/zgoome-infra`
- **Application repos**: `zgoome/movie-backend`, `zgoome/movie-frontend`

## Common Commands

### Create Sealed Secret

Use the interactive script to create encrypted secrets:

```bash
./scripts/create-sealed-secret.sh
```

The script will:
1. Prompt for secret name and namespace
2. Ask for scope selection (namespace-wide/strict/cluster-wide)
3. Collect key-value pairs interactively
4. Generate sealed secret in `manifests/secrets/`
5. Optionally commit and push changes

**Auto-detected kubeconfig** (in order):
1. `$KUBECONFIG` environment variable
2. `/etc/rancher/k3s/k3s.yaml` (if on k3s server)
3. `~/.kube/config` (standard kubectl config)

### Prerequisites

- `kubectl` with cluster access
- `kubeseal` CLI tool
- Sealed Secrets Controller running in `kube-system` namespace

### ArgoCD Sync

Applications auto-sync with `prune: true` and `selfHeal: true`. Manual sync:

```bash
# Sync root application (syncs all child apps)
argocd app sync zgoome-infra

# Sync specific application
argocd app sync <app-name>
```

### Verify Deployment Order

Check sync wave annotations to understand deployment sequence:

```bash
# View all applications with sync waves
kubectl get applications -n argocd -o custom-columns=NAME:.metadata.name,WAVE:.metadata.annotations."argocd\.argoproj\.io/sync-wave"
```

## Important Conventions

### Sealed Secret Naming

- **File naming**: `sealed-{SECRET_NAME}-{NAMESPACE}.yaml`
- **Location**: `manifests/secrets/`
- **Annotations**: Include scope annotation in secret metadata before sealing

### ArgoCD Application Naming

- Helm apps use chart name (e.g., `prometheus-stack`, `loki`)
- Environment-specific apps include environment (e.g., `movie-api-development`, `movie-ui-production`)
- Database apps include DB type (e.g., `postgres-db`)

### Namespace Organization

- `argocd`: ArgoCD applications
- `monitoring`: Prometheus, Grafana, Loki, Promtail
- `db`: PostgreSQL and other databases
- `movie`: Movie application (dev and prod)
- `kube-system`: Sealed Secrets Controller

### Git Repository Access

- **IMPORTANT**: ArgoCD applications MUST only use repositories from the `zgoome` GitHub organization
- All application repositories should be under `github.com/zgoome/*`
- Use SSH URLs for private repositories: `git@github.com:zgoome/repo.git`
- Use HTTPS URLs for public Helm charts: `https://prometheus-community.github.io/helm-charts`

**Allowed repository pattern**:
- Infrastructure: `git@github.com:zgoome/zgoome-infra.git` or `https://github.com/zgoome/zgoome-infra.git`
- Applications: `https://github.com/zgoome/movie-backend.git`, `https://github.com/zgoome/movie-frontend.git`, etc.
- Helm charts: Public Helm repositories (e.g., Prometheus, Grafana)

---

## 🔍 규칙 추가 프로세스

### 명령어

```
[규칙 추가] {카테고리} - {규칙 내용}
```

### 자동 실행

#### 1단계: 중복 체크
- 키워드 추출 및 기존 파일 비교
- 유사도 50%+ 시 알림

#### 2단계: 유사 규칙 발견 시

```
⚠️ 유사한 규칙이 이미 존재합니다!

기존: [{카테고리}] - .claude/info/{파일명}.md
키워드 일치: "{키워드1}", "{키워드2}"

📋 현재 규칙 요약:
  • 항목 1
  • 항목 2

🆕 새로운 내용: "{규칙}"

선택하세요:
1️⃣ 기존 파일에 추가
2️⃣ 새 파일 생성
3️⃣ 취소
```

#### 3단계: 처리
- **1️⃣**: 기존 파일 업데이트
- **2️⃣**: 새 파일 생성 + CLAUDE.md 태그 추가
- **3️⃣**: 취소

### 키워드 매칭

| 카테고리 | 키워드 | 파일명 |
|----------|--------|--------|
| Git | git, commit, branch, merge, pr | git-*.md |
| ArgoCD | argocd, gitops, sync, application | argocd-*.md |
| Kubernetes | k8s, kubernetes, manifest, deployment | k8s-*.md |
| Secrets | secret, sealed-secret, kubeseal | secrets-*.md |
| Monitoring | prometheus, grafana, loki, alert | monitoring-*.md |
| 배포 | deploy, release, build, ci, cd | deployment-*.md |
| 문서 | doc, readme, comment | documentation-*.md |

**유사도 판단:**
- 키워드 2개+ 일치
- 태그명 50%+ 유사
- 파일명 패턴 일치

---

## 📌 추가 태그 시스템

확장 가능한 태그 예시:

### 작업 유형
- `[추가]` - 새 기능
- `[수정]` - 코드 수정
- `[삭제]` - 코드 제거
- `[리팩토링]` - 리팩토링

### 우선순위
- `[긴급]` - 긴급
- `[중요]` - 중요
- `[일반]` - 일반

<!-- 프로젝트별로 필요한 태그를 자유롭게 추가하세요 -->

---

## 프로젝트별 커스텀 내용

<!-- 여기에 프로젝트 특화 내용을 추가하세요 -->
