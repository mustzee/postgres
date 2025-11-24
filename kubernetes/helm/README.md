# Helm Chart로 PostgreSQL 배포

## 🎯 개요

Bitnami PostgreSQL Helm Chart를 사용한 프로덕션급 배포입니다.
검증된 설정으로 빠르게 배포할 수 있습니다.

## ✅ 장점

- ✅ 검증된 프로덕션 설정
- ✅ 쉬운 업그레이드 및 롤백
- ✅ HA (High Availability) 지원
- ✅ Streaming Replication 자동 구성
- ✅ 백업/복구 기능 내장
- ✅ 모니터링 메트릭 내보내기
- ✅ PgBouncer 통합 가능

## 📋 사전 준비

```bash
# Helm 설치 확인
helm version

# Helm이 없다면 설치
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Windows
choco install kubernetes-helm
```

## 🚀 빠른 시작

### 1. Helm Repository 추가

```bash
# Bitnami repository 추가
helm repo add bitnami https://charts.bitnami.com/bitnami

# Repository 업데이트
helm repo update

# Chart 검색
helm search repo postgresql
```

### 2. 기본 배포

```bash
# 간단한 배포 (기본 설정)
helm install my-postgres bitnami/postgresql \
  --namespace postgres \
  --create-namespace

# 배포 확인
helm list -n postgres
kubectl get pods -n postgres
```

### 3. 커스텀 설정으로 배포 (권장)

```bash
# values.yaml 사용
helm install my-postgres bitnami/postgresql \
  --namespace postgres \
  --create-namespace \
  --values values.yaml

# 또는 명령줄 옵션
helm install my-postgres bitnami/postgresql \
  --namespace postgres \
  --create-namespace \
  --set auth.postgresPassword=SecurePassword123! \
  --set primary.persistence.size=20Gi \
  --set readReplicas.replicaCount=2
```

### 4. 비밀번호 확인

```bash
# PostgreSQL 비밀번호 가져오기
export POSTGRES_PASSWORD=$(kubectl get secret --namespace postgres my-postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)

echo "PostgreSQL Password: $POSTGRES_PASSWORD"
```

## 🔌 PostgreSQL 접속

### 클러스터 내부에서

```bash
# Primary (읽기/쓰기)
kubectl run my-postgres-postgresql-client \
  --rm --tty -i --restart='Never' \
  --namespace postgres \
  --image docker.io/bitnami/postgresql:16 \
  --env="PGPASSWORD=$POSTGRES_PASSWORD" \
  --command -- psql \
  --host my-postgres-postgresql \
  --port 5432 \
  --username postgres \
  --dbname postgres

# Read Replica (읽기 전용)
# 서비스명: my-postgres-postgresql-read
```

### 로컬에서 (Port Forward)

```bash
# Primary 포트 포워딩
kubectl port-forward --namespace postgres \
  svc/my-postgres-postgresql 5432:5432 &

# 연결
PGPASSWORD="$POSTGRES_PASSWORD" psql \
  --host 127.0.0.1 \
  --port 5432 \
  --username postgres \
  --dbname postgres
```

### 애플리케이션에서 연결

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  # Primary (읽기/쓰기)
  DATABASE_HOST: "my-postgres-postgresql.postgres.svc.cluster.local"
  DATABASE_PORT: "5432"
  DATABASE_NAME: "postgres"
  DATABASE_USER: "postgres"

  # Read Replica (읽기 전용)
  DATABASE_READ_HOST: "my-postgres-postgresql-read.postgres.svc.cluster.local"

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:latest
        env:
        - name: DATABASE_URL
          value: "postgresql://$(DATABASE_USER):$(POSTGRES_PASSWORD)@$(DATABASE_HOST):$(DATABASE_PORT)/$(DATABASE_NAME)"
        - name: DATABASE_USER
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: DATABASE_USER
        - name: DATABASE_HOST
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: DATABASE_HOST
        - name: DATABASE_PORT
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: DATABASE_PORT
        - name: DATABASE_NAME
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: DATABASE_NAME
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: my-postgres-postgresql
              key: postgres-password
```

## 🔧 주요 설정 (values.yaml)

values.yaml 파일을 참조하세요.

### 핵심 설정 요약

```yaml
# 인증
auth:
  postgresPassword: "SecurePassword123!"
  database: "myapp"
  username: "myapp"
  password: "MyAppPassword123!"

# Primary 설정
primary:
  persistence:
    size: 20Gi
    storageClass: "gp3"  # 클라우드에 맞게 변경

  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "2Gi"
      cpu: "2000m"

# Read Replicas (HA)
readReplicas:
  replicaCount: 2
  persistence:
    size: 20Gi
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "2Gi"
      cpu: "2000m"

# 메트릭 (Prometheus)
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
```

## 📊 모니터링

### Prometheus Exporter 활성화

```yaml
# values.yaml
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: monitoring
    labels:
      release: prometheus
```

### Grafana Dashboard

1. Grafana에서 Dashboard Import
2. Dashboard ID: `9628` (PostgreSQL Database)
3. Prometheus 데이터 소스 선택

## 🔄 운영 작업

### 업그레이드

```bash
# Chart 버전 업그레이드
helm repo update
helm upgrade my-postgres bitnami/postgresql \
  --namespace postgres \
  --values values.yaml

# PostgreSQL 버전 업그레이드
helm upgrade my-postgres bitnami/postgresql \
  --namespace postgres \
  --set image.tag=17-debian-12 \
  --values values.yaml

# 상태 확인
helm status my-postgres -n postgres
```

### 롤백

```bash
# 히스토리 확인
helm history my-postgres -n postgres

# 이전 버전으로 롤백
helm rollback my-postgres 1 -n postgres
```

### 스케일링

```bash
# Read Replica 개수 변경
helm upgrade my-postgres bitnami/postgresql \
  --namespace postgres \
  --set readReplicas.replicaCount=3 \
  --values values.yaml
```

### 백업

```bash
# Primary Pod에서 백업
kubectl exec -n postgres my-postgres-postgresql-0 -- \
  pg_dumpall -U postgres > backup_$(date +%Y%m%d).sql

# 또는 CronJob으로 자동 백업
kubectl apply -f backup-cronjob.yaml
```

### 복구

```bash
# SQL 파일로 복구
kubectl exec -i -n postgres my-postgres-postgresql-0 -- \
  psql -U postgres < backup_20241124.sql
```

## 🧪 테스트

### 읽기/쓰기 테스트

```bash
# Primary에 데이터 삽입
kubectl exec -n postgres my-postgres-postgresql-0 -- \
  psql -U postgres -c "CREATE TABLE test (id SERIAL, data TEXT);"

kubectl exec -n postgres my-postgres-postgresql-0 -- \
  psql -U postgres -c "INSERT INTO test (data) VALUES ('hello');"

# Read Replica에서 조회
kubectl exec -n postgres my-postgres-postgresql-read-0 -- \
  psql -U postgres -c "SELECT * FROM test;"
```

### Replication 확인

```bash
# Primary 상태
kubectl exec -n postgres my-postgres-postgresql-0 -- \
  psql -U postgres -c "SELECT * FROM pg_stat_replication;"

# Replica 상태
kubectl exec -n postgres my-postgres-postgresql-read-0 -- \
  psql -U postgres -c "SELECT * FROM pg_stat_wal_receiver;"
```

## 🧹 삭제

### Helm Release 삭제

```bash
# Release 삭제
helm uninstall my-postgres -n postgres

# PVC 삭제 (주의: 데이터 손실!)
kubectl delete pvc -n postgres -l app.kubernetes.io/instance=my-postgres

# Namespace 삭제
kubectl delete namespace postgres
```

## 🆚 다른 방법과 비교

| 항목 | StatefulSet | Helm Chart | CloudNativePG |
|------|------------|------------|---------------|
| 배포 난이도 | 어려움 | 쉬움 | 중간 |
| HA 구성 | 수동 | 자동 | 자동 |
| 백업/복구 | 수동 | 수동 | 자동 |
| 업그레이드 | 복잡 | 간단 | 간단 |
| 커스터마이징 | 완전 제어 | 제한적 | 유연함 |
| 프로덕션 | ❌ | ✅ | ✅✅ |

## 💡 Best Practices

1. **항상 values.yaml 사용**
   ```bash
   helm upgrade my-postgres bitnami/postgresql \
     --values values.yaml \
     --namespace postgres
   ```

2. **비밀번호는 Secret으로**
   ```bash
   # 기존 Secret 사용
   helm install my-postgres bitnami/postgresql \
     --set auth.existingSecret=postgres-secret \
     --namespace postgres
   ```

3. **리소스 제한 설정**
   ```yaml
   primary:
     resources:
       requests:
         memory: "1Gi"
       limits:
         memory: "2Gi"
   ```

4. **PVC 크기 충분히**
   ```yaml
   primary:
     persistence:
       size: 100Gi  # 데이터 증가 고려
   ```

5. **Read Replica 활용**
   ```yaml
   readReplicas:
     replicaCount: 2  # 읽기 부하 분산
   ```

## 📚 참고 자료

- [Bitnami PostgreSQL Chart](https://github.com/bitnami/charts/tree/main/bitnami/postgresql)
- [Chart Parameters](https://github.com/bitnami/charts/blob/main/bitnami/postgresql/values.yaml)
- [Helm Documentation](https://helm.sh/docs/)

---

**추천 환경**: 프로덕션, 스테이징
**난이도**: ⭐⭐☆☆☆
