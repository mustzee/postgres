# Kubernetes에서 PostgreSQL 운영하기

## 🎯 학습 목표

- Kubernetes에서 StatefulSet으로 PostgreSQL 배포
- Helm Chart를 활용한 프로덕션급 배포
- PostgreSQL Operators (CloudNativePG) 사용
- 백업, 모니터링, 고가용성 구성

## 📚 배포 방법 비교

### 1. StatefulSet (기본)
✅ **장점**:
- Kubernetes 네이티브
- 완전한 제어
- 학습 목적에 좋음

❌ **단점**:
- 설정이 복잡
- 백업/복구 수동 구성 필요
- HA 구성 어려움

**추천 용도**: 개발/테스트 환경, 학습

### 2. Helm Chart (Bitnami)
✅ **장점**:
- 검증된 프로덕션 설정
- 쉬운 배포 및 업그레이드
- 백업/모니터링 통합

❌ **단점**:
- 커스터마이징 제한적
- Helm 지식 필요

**추천 용도**: 빠른 프로덕션 배포

### 3. Operators (CloudNativePG)
✅ **장점**:
- 자동화된 운영 (백업, 복구, 장애조치)
- Declarative HA 구성
- Kubernetes 네이티브 경험
- PITR 자동 지원

❌ **단점**:
- 학습 곡선
- Operator 의존성

**추천 용도**: 프로덕션 환경 (강력 추천!)

### 4. 클라우드 관리형 (RDS, Cloud SQL)
✅ **장점**:
- 완전 관리형
- 자동 백업/패치
- 고가용성 기본 제공

❌ **단점**:
- 비용
- 벤더 종속성
- Kubernetes 통합 약함

**추천 용도**: 운영 부담을 최소화하고 싶을 때

## 🗂️ 디렉토리 구조

```
kubernetes/
├── basic/              # StatefulSet 기본 배포
│   ├── statefulset.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   └── pvc.yaml
│
├── helm/               # Helm Chart 배포
│   ├── values.yaml
│   └── README.md
│
├── operators/          # CloudNativePG Operator
│   ├── cluster.yaml
│   ├── backup.yaml
│   └── README.md
│
└── monitoring/         # Prometheus + Grafana
    ├── servicemonitor.yaml
    └── dashboard.json
```

## 🚀 빠른 시작

### 전제 조건

```bash
# Kubernetes 클러스터 필요 (아래 중 하나)
# - minikube
# - kind
# - Docker Desktop Kubernetes
# - GKE, EKS, AKS

# kubectl 설치 확인
kubectl version --client

# Helm 설치 확인 (옵션)
helm version
```

### 방법 1: StatefulSet (기본)

```bash
# 네임스페이스 생성
kubectl create namespace postgres

# Secret 생성 (비밀번호)
kubectl create secret generic postgres-secret \
  --from-literal=password=YourSecurePassword123! \
  -n postgres

# 배포
kubectl apply -f kubernetes/basic/ -n postgres

# 확인
kubectl get pods -n postgres
kubectl get pvc -n postgres
```

### 방법 2: Helm Chart (권장)

```bash
# Bitnami Helm repository 추가
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# 배포
helm install my-postgres bitnami/postgresql \
  --namespace postgres \
  --create-namespace \
  --values kubernetes/helm/values.yaml

# 확인
helm list -n postgres
kubectl get pods -n postgres
```

### 방법 3: CloudNativePG Operator (프로덕션 추천!)

```bash
# Operator 설치
kubectl apply -f \
  https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/main/releases/cnpg-1.22.0.yaml

# PostgreSQL Cluster 생성
kubectl apply -f kubernetes/operators/cluster.yaml -n postgres

# 확인
kubectl get cluster -n postgres
kubectl get pods -n postgres
```

## 🔗 다음 단계

1. [기본 StatefulSet 배포](./basic/README.md)
2. [Helm Chart 배포](./helm/README.md)
3. [CloudNativePG Operator](./operators/README.md) ⭐ **강력 추천**
4. [모니터링 설정](./monitoring/README.md)

## 💡 프로덕션 체크리스트

- [ ] PersistentVolume 스토리지 클래스 확인 (gp3, pd-ssd 등)
- [ ] Secret으로 비밀번호 관리
- [ ] Resource limits/requests 설정
- [ ] HA 구성 (최소 3 replicas)
- [ ] 백업 전략 수립 (자동 백업)
- [ ] PITR 활성화
- [ ] 모니터링 설정 (Prometheus + Grafana)
- [ ] Connection Pooling (PgBouncer)
- [ ] NetworkPolicy 설정 (보안)
- [ ] 재해 복구 계획

## 🆚 환경별 추천

| 환경 | 추천 방법 | 이유 |
|------|----------|------|
| **로컬 개발** | Docker Compose | 가장 간단, 빠른 시작 |
| **개발 클러스터** | StatefulSet | Kubernetes 학습 |
| **스테이징** | Helm Chart | 프로덕션 유사 환경 |
| **프로덕션 (소규모)** | CloudNativePG | 자동화된 운영 |
| **프로덕션 (대규모)** | RDS/Cloud SQL | 완전 관리형 |

## 📖 학습 순서

1. **Docker Compose로 시작** (현재 완료)
   - 로컬에서 PostgreSQL 이해
   - SQL 학습

2. **기본 StatefulSet 배포**
   - Kubernetes 리소스 이해
   - PVC, ConfigMap, Secret

3. **Helm Chart 사용**
   - 프로덕션 설정 이해
   - values.yaml 커스터마이징

4. **CloudNativePG 마스터** ⭐
   - Operator 패턴 이해
   - 자동화된 백업/복구
   - HA 구성

5. **모니터링 추가**
   - Prometheus Exporter
   - Grafana Dashboard
   - 알람 설정

---

**시작**: Docker Compose (학습) → **중간**: Helm Chart (편리함) → **최종**: CloudNativePG (프로덕션)
