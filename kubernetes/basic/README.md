# StatefulSet으로 PostgreSQL 배포

## 🎯 개요

Kubernetes StatefulSet을 사용한 기본 PostgreSQL 배포입니다.
학습 및 개발 환경에 적합합니다.

## 📋 구성 요소

1. **Secret**: PostgreSQL 비밀번호
2. **ConfigMap**: postgresql.conf 설정
3. **PersistentVolumeClaim**: 데이터 영구 저장
4. **StatefulSet**: PostgreSQL Pod 관리
5. **Service**: 네트워크 접근

## 🚀 배포

### 1. 네임스페이스 생성

```bash
kubectl create namespace postgres
```

### 2. Secret 생성

```bash
# 명령어로 생성 (간단)
kubectl create secret generic postgres-secret \
  --from-literal=postgres-password=YourSecurePassword123! \
  --from-literal=replication-password=ReplicationPass123! \
  -n postgres

# 또는 YAML 사용
kubectl apply -f secret.yaml -n postgres
```

### 3. ConfigMap 생성

```bash
kubectl apply -f configmap.yaml -n postgres
```

### 4. StatefulSet 및 Service 배포

```bash
kubectl apply -f statefulset.yaml -n postgres
kubectl apply -f service.yaml -n postgres
```

### 5. 배포 확인

```bash
# Pod 상태 확인
kubectl get pods -n postgres

# StatefulSet 확인
kubectl get statefulset -n postgres

# Service 확인
kubectl get svc -n postgres

# PVC 확인
kubectl get pvc -n postgres

# 로그 확인
kubectl logs postgres-0 -n postgres
```

## 🔌 PostgreSQL 접속

### 클러스터 내부에서 접속

```bash
# psql 실행
kubectl exec -it postgres-0 -n postgres -- psql -U postgres

# 다른 Pod에서 접속
# Service DNS: postgres.postgres.svc.cluster.local:5432
```

### 로컬에서 접속 (Port Forward)

```bash
# 포트 포워딩
kubectl port-forward svc/postgres 5432:5432 -n postgres

# 다른 터미널에서 접속
psql -h localhost -U postgres -d postgres
# Password: YourSecurePassword123!
```

### 애플리케이션에서 연결

```yaml
# 애플리케이션 Deployment 예시
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
          value: "postgresql://postgres:$(POSTGRES_PASSWORD)@postgres.postgres.svc.cluster.local:5432/mydb"
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: postgres-password
```

## 📊 모니터링

### Pod 리소스 사용량

```bash
kubectl top pod postgres-0 -n postgres
```

### 로그 확인

```bash
# 실시간 로그
kubectl logs -f postgres-0 -n postgres

# 최근 100줄
kubectl logs --tail=100 postgres-0 -n postgres
```

### 이벤트 확인

```bash
kubectl get events -n postgres --sort-by='.lastTimestamp'
```

## 🔧 운영 작업

### 데이터베이스 백업

```bash
# pg_dump로 백업
kubectl exec postgres-0 -n postgres -- \
  pg_dump -U postgres -d postgres > backup.sql

# 또는 컨테이너 내부에서
kubectl exec -it postgres-0 -n postgres -- bash
pg_dump -U postgres -d postgres > /tmp/backup.sql
```

### 백업 파일 복사

```bash
# Pod에서 로컬로
kubectl cp postgres/postgres-0:/tmp/backup.sql ./backup.sql

# 로컬에서 Pod로
kubectl cp ./backup.sql postgres/postgres-0:/tmp/backup.sql
```

### 복구

```bash
# SQL 파일로 복구
kubectl exec -i postgres-0 -n postgres -- \
  psql -U postgres -d postgres < backup.sql
```

### 스케일링 (주의!)

```bash
# StatefulSet은 수동 스케일링만 권장
# Read Replica 추가 시 replication 설정 필요
kubectl scale statefulset postgres --replicas=3 -n postgres
```

## 🛠️ 트러블슈팅

### Pod이 Pending 상태

```bash
# PVC 상태 확인
kubectl get pvc -n postgres

# StorageClass 확인
kubectl get storageclass

# 이벤트 확인
kubectl describe pod postgres-0 -n postgres
```

**해결**:
- StorageClass가 존재하는지 확인
- PV 프로비저너가 동작하는지 확인

### Pod이 CrashLoopBackOff

```bash
# 로그 확인
kubectl logs postgres-0 -n postgres --previous

# Pod 상세 정보
kubectl describe pod postgres-0 -n postgres
```

**일반적인 원인**:
- 비밀번호 Secret이 없음
- 잘못된 설정 (ConfigMap)
- 권한 문제
- 리소스 부족

### 연결 실패

```bash
# Service 확인
kubectl get svc postgres -n postgres

# Endpoints 확인
kubectl get endpoints postgres -n postgres

# Pod IP 확인
kubectl get pod postgres-0 -n postgres -o wide
```

**체크리스트**:
- Service가 올바른 Pod을 가리키는지
- NetworkPolicy가 차단하지 않는지
- 비밀번호가 올바른지

## 🔄 업그레이드

### PostgreSQL 버전 업그레이드

```bash
# 1. 백업 (필수!)
kubectl exec postgres-0 -n postgres -- \
  pg_dumpall -U postgres > full_backup.sql

# 2. StatefulSet 이미지 업데이트
kubectl set image statefulset/postgres \
  postgres=postgres:17-alpine \
  -n postgres

# 3. 롤아웃 상태 확인
kubectl rollout status statefulset/postgres -n postgres

# 4. 검증
kubectl exec postgres-0 -n postgres -- psql -U postgres -c "SELECT version();"
```

## 🧹 삭제

### 전체 삭제

```bash
# StatefulSet 삭제 (Pod도 삭제됨)
kubectl delete statefulset postgres -n postgres

# Service 삭제
kubectl delete svc postgres -n postgres

# PVC 삭제 (주의: 데이터 손실!)
kubectl delete pvc postgres-data-postgres-0 -n postgres

# ConfigMap, Secret 삭제
kubectl delete configmap postgres-config -n postgres
kubectl delete secret postgres-secret -n postgres

# 네임스페이스 전체 삭제
kubectl delete namespace postgres
```

### StatefulSet만 삭제 (데이터 보존)

```bash
# StatefulSet 삭제, PVC는 유지
kubectl delete statefulset postgres -n postgres

# 나중에 재생성하면 기존 PVC 재사용됨
kubectl apply -f statefulset.yaml -n postgres
```

## ⚠️ 주의사항

1. **프로덕션 사용 비추천**
   - HA 없음 (단일 Pod)
   - 자동 백업 없음
   - 장애조치 수동

2. **PVC 삭제 주의**
   - StatefulSet 삭제해도 PVC는 유지됨
   - PVC 삭제 = 데이터 손실

3. **리소스 제한**
   - 반드시 limits/requests 설정
   - OOM Killer 방지

4. **보안**
   - 비밀번호를 Secret으로 관리
   - RBAC 설정 권장
   - NetworkPolicy 고려

## 📚 다음 단계

- [Helm Chart 배포](../helm/README.md) - 더 쉬운 관리
- [CloudNativePG](../operators/README.md) - 프로덕션 권장
- [모니터링 설정](../monitoring/README.md)

---

**용도**: 학습, 개발 환경
**프로덕션**: CloudNativePG Operator 권장
