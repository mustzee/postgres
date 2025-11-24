# CloudNativePG Operator로 PostgreSQL 운영

## 🎯 개요

**CloudNativePG**는 Kubernetes에서 PostgreSQL을 운영하기 위한 가장 현대적이고 권장되는 방법입니다.

## 🌟 왜 CloudNativePG인가?

### ✅ 주요 장점

1. **완전 자동화된 운영**
   - 자동 장애조치 (Automatic Failover)
   - 자동 백업 및 복구
   - 자동 WAL 아카이빙

2. **Kubernetes 네이티브**
   - CRD (Custom Resource Definition) 사용
   - Declarative 설정
   - GitOps 친화적

3. **프로덕션 준비 완료**
   - Streaming Replication
   - PITR (Point-in-Time Recovery)
   - Connection Pooling (PgBouncer 내장)
   - Monitoring (Prometheus 통합)

4. **강력한 백업 기능**
   - S3, GCS, Azure Blob 지원
   - 스케줄 기반 자동 백업
   - WAL 지속적 아카이빙

### 🆚 다른 Operators와 비교

| 기능 | CloudNativePG | Zalando | Crunchy |
|------|--------------|---------|---------|
| 활발한 개발 | ✅ | ⚠️ | ✅ |
| PITR | ✅ | ✅ | ✅ |
| 내장 Pooling | ✅ | ❌ | ✅ |
| S3 백업 | ✅ | ⚠️ | ✅ |
| 학습 곡선 | 낮음 | 중간 | 높음 |
| 라이선스 | Apache 2.0 | MIT | Apache 2.0 |

**결론**: CloudNativePG 추천! 🚀

## 📋 사전 준비

```bash
# Kubernetes 클러스터 필요 (1.23+)
kubectl version

# kubectl-cnpg 플러그인 설치 (옵션)
curl -sSfL \
  https://github.com/cloudnative-pg/cloudnative-pg/raw/main/hack/install-cnpg-plugin.sh | \
  sudo sh -s -- -b /usr/local/bin
```

## 🚀 빠른 시작

### 1. Operator 설치

```bash
# Operator 배포
kubectl apply -f \
  https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.22/releases/cnpg-1.22.0.yaml

# Operator 확인
kubectl get deployment -n cnpg-system cnpg-controller-manager

# Pod 확인
kubectl get pods -n cnpg-system
```

### 2. 첫 PostgreSQL Cluster 생성

```bash
# 네임스페이스 생성
kubectl create namespace postgres

# Cluster 배포
kubectl apply -f cluster.yaml -n postgres

# 상태 확인
kubectl get cluster -n postgres
kubectl get pods -n postgres

# 상세 정보
kubectl describe cluster postgres-cluster -n postgres
```

### 3. 연결 테스트

```bash
# Primary Pod 찾기
kubectl get pods -n postgres -L cnpg.io/role

# psql 접속
kubectl exec -it postgres-cluster-1 -n postgres -- psql -U app

# 또는 kubectl-cnpg 플러그인 사용
kubectl cnpg psql postgres-cluster -n postgres
```

## 📁 Cluster 설정 (cluster.yaml)

기본 예제는 `cluster.yaml` 참조

### 핵심 설정

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres-cluster
spec:
  # 인스턴스 수 (1 Primary + N Replicas)
  instances: 3  # HA를 위해 최소 3개 권장

  # PostgreSQL 버전
  imageName: ghcr.io/cloudnative-pg/postgresql:16

  # 스토리지
  storage:
    size: 20Gi
    storageClass: gp3  # 클라우드에 맞게

  # 부트스트랩 (초기화)
  bootstrap:
    initdb:
      database: app
      owner: app
      secret:
        name: app-secret

  # 백업 설정
  backup:
    barmanObjectStore:
      destinationPath: s3://my-backups/postgres/
      s3Credentials:
        accessKeyId:
          name: aws-creds
          key: ACCESS_KEY_ID
        secretAccessKey:
          name: aws-creds
          key: ACCESS_SECRET_KEY
      wal:
        compression: gzip
        maxParallel: 2
    retentionPolicy: "30d"

  # 모니터링
  monitoring:
    enablePodMonitor: true
```

## 🔌 애플리케이션 연결

### 1. Service 확인

```bash
# CloudNativePG가 자동 생성한 Service 확인
kubectl get svc -n postgres

# 출력 예시:
# postgres-cluster-rw    ClusterIP   10.0.0.1   5432/TCP  # Primary (Read-Write)
# postgres-cluster-ro    ClusterIP   10.0.0.2   5432/TCP  # Replicas (Read-Only)
# postgres-cluster-r     ClusterIP   10.0.0.3   5432/TCP  # 모든 인스턴스 (Read)
```

### 2. 연결 정보

```yaml
# Read-Write (Primary만)
DATABASE_HOST: postgres-cluster-rw.postgres.svc.cluster.local
DATABASE_PORT: 5432

# Read-Only (Replicas만)
DATABASE_READ_HOST: postgres-cluster-ro.postgres.svc.cluster.local

# Read (모든 인스턴스)
DATABASE_READ_ALL_HOST: postgres-cluster-r.postgres.svc.cluster.local
```

### 3. 애플리케이션 Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: postgres
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:latest
        env:
        # Primary (쓰기)
        - name: DATABASE_URL
          value: "postgresql://app:$(APP_PASSWORD)@postgres-cluster-rw:5432/app"

        # Read Replica (읽기)
        - name: DATABASE_READ_URL
          value: "postgresql://app:$(APP_PASSWORD)@postgres-cluster-ro:5432/app"

        - name: APP_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secret
              key: password
```

## 💾 백업 및 복구

### 1. S3 백업 설정

```bash
# AWS Credentials Secret 생성
kubectl create secret generic aws-creds \
  --from-literal=ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE \
  --from-literal=ACCESS_SECRET_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \
  -n postgres

# Cluster에 백업 설정 추가 (cluster-with-backup.yaml 참조)
kubectl apply -f cluster-with-backup.yaml -n postgres
```

### 2. 수동 백업

```yaml
# backup.yaml
apiVersion: postgresql.cnpg.io/v1
kind: Backup
metadata:
  name: manual-backup
  namespace: postgres
spec:
  cluster:
    name: postgres-cluster
```

```bash
kubectl apply -f backup.yaml -n postgres

# 백업 상태 확인
kubectl get backup -n postgres
kubectl describe backup manual-backup -n postgres
```

### 3. 스케줄 백업

```yaml
# scheduled-backup.yaml
apiVersion: postgresql.cnpg.io/v1
kind: ScheduledBackup
metadata:
  name: daily-backup
  namespace: postgres
spec:
  schedule: "0 2 * * *"  # 매일 새벽 2시
  backupOwnerReference: self
  cluster:
    name: postgres-cluster
```

```bash
kubectl apply -f scheduled-backup.yaml -n postgres

# 백업 스케줄 확인
kubectl get scheduledbackup -n postgres
```

### 4. PITR (Point-in-Time Recovery)

```yaml
# restore-pitr.yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres-cluster-restored
spec:
  instances: 3

  bootstrap:
    recovery:
      source: postgres-cluster
      recoveryTarget:
        targetTime: "2024-11-24 14:30:00 UTC"

  externalClusters:
  - name: postgres-cluster
    barmanObjectStore:
      destinationPath: s3://my-backups/postgres/
      s3Credentials:
        accessKeyId:
          name: aws-creds
          key: ACCESS_KEY_ID
        secretAccessKey:
          name: aws-creds
          key: ACCESS_SECRET_KEY
```

```bash
# 특정 시점으로 복구
kubectl apply -f restore-pitr.yaml -n postgres

# 복구 상태 확인
kubectl get cluster postgres-cluster-restored -n postgres
```

## 🔄 고가용성 (HA) 및 장애조치

### 자동 장애조치 테스트

```bash
# Primary Pod 삭제 (장애 시뮬레이션)
PRIMARY_POD=$(kubectl get pods -n postgres -l cnpg.io/role=primary -o name)
kubectl delete $PRIMARY_POD -n postgres

# 자동 장애조치 관찰
kubectl get pods -n postgres -L cnpg.io/role -w

# 몇 초 내에 새로운 Primary 선출됨!
```

### Replica 추가

```bash
# instances 수 증가
kubectl cnpg scale postgres-cluster --replicas=5 -n postgres

# 또는 YAML 수정
kubectl edit cluster postgres-cluster -n postgres
# spec.instances: 5

# Pod 확인
kubectl get pods -n postgres
```

## 📊 모니터링

### Prometheus Integration

```bash
# PodMonitor 자동 생성 확인
kubectl get podmonitor -n postgres

# Prometheus에서 확인할 메트릭:
# - cnpg_pg_stat_database_*
# - cnpg_pg_replication_*
# - cnpg_pg_stat_archiver_*
```

### 커스텀 쿼리 모니터링

```yaml
# cluster.yaml에 추가
spec:
  monitoring:
    customQueries:
    - name: "table_sizes"
      query: |
        SELECT
          schemaname,
          tablename,
          pg_total_relation_size(schemaname||'.'||tablename) AS size
        FROM pg_tables
        WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
      metrics:
      - name: "table_size_bytes"
        description: "Table size in bytes"
        usageType: GAUGE
```

### kubectl-cnpg 플러그인 사용

```bash
# Cluster 상태
kubectl cnpg status postgres-cluster -n postgres

# 백업 목록
kubectl cnpg backup postgres-cluster -n postgres

# 복구 가능 시간 범위
kubectl cnpg fencing postgres-cluster -n postgres
```

## 🛠️ 운영 작업

### PostgreSQL 버전 업그레이드

```bash
# 이미지 변경 (자동 롤링 업데이트)
kubectl cnpg upgrade postgres-cluster \
  --image ghcr.io/cloudnative-pg/postgresql:17 \
  -n postgres

# 업그레이드 진행 확인
kubectl get cluster postgres-cluster -n postgres -w
```

### 설정 변경

```yaml
# PostgreSQL 설정 (postgresql.conf)
spec:
  postgresql:
    parameters:
      max_connections: "200"
      shared_buffers: "512MB"
      work_mem: "8MB"
```

```bash
kubectl edit cluster postgres-cluster -n postgres

# Pod가 자동으로 재시작됨 (롤링 업데이트)
```

### Connection Pooling (PgBouncer)

```yaml
spec:
  # PgBouncer 활성화
  pgbouncer:
    pooler:
      instances: 3
      parameters:
        max_client_conn: "1000"
        default_pool_size: "25"
```

## 🧹 삭제

```bash
# Cluster 삭제
kubectl delete cluster postgres-cluster -n postgres

# PVC는 자동 삭제되지 않음 (데이터 보호)
kubectl get pvc -n postgres

# PVC도 삭제하려면
kubectl delete pvc -n postgres -l cnpg.io/cluster=postgres-cluster

# Operator 삭제 (모든 Cluster 삭제 후)
kubectl delete -f \
  https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.22/releases/cnpg-1.22.0.yaml
```

## 📚 추가 학습 자료

- [CloudNativePG 공식 문서](https://cloudnative-pg.io/)
- [GitHub Repository](https://github.com/cloudnative-pg/cloudnative-pg)
- [Examples](https://github.com/cloudnative-pg/cloudnative-pg/tree/main/docs/src/samples)

## 💡 Best Practices

1. **최소 3개 인스턴스** - HA 구성
2. **자동 백업 설정** - S3, GCS 등
3. **PITR 활성화** - WAL 아카이빙
4. **모니터링 필수** - Prometheus + Grafana
5. **PgBouncer 사용** - Connection Pooling
6. **정기적인 테스트** - 장애조치, 복구 연습

---

**추천 환경**: 프로덕션 (강력 추천!)
**난이도**: ⭐⭐⭐☆☆
**완성도**: ⭐⭐⭐⭐⭐
