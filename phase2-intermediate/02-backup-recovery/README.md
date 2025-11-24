# 02. 백업 및 복구

## 🎯 학습 목표

- PostgreSQL 백업 방법 이해
- pg_dump, pg_restore 마스터
- 지속적 아카이빙 및 PITR (Point-in-Time Recovery)
- 클라우드 백업 전략

## 📦 백업 유형

### 1. 논리적 백업 (Logical Backup)
- **pg_dump**: SQL 스크립트로 백업
- 장점: 이식성, 버전 간 호환성
- 단점: 느림, 큰 데이터베이스에 부적합

### 2. 물리적 백업 (Physical Backup)
- **pg_basebackup**: 파일 시스템 수준 백업
- 장점: 빠름, PITR 가능
- 단점: 같은 버전만 가능

### 3. 지속적 아카이빙 (Continuous Archiving)
- **WAL (Write-Ahead Logging)**: 트랜잭션 로그 백업
- PITR 지원

## 🔧 pg_dump 사용법

### 기본 사용법

```bash
# 단일 데이터베이스 백업
pg_dump -U postgres -d learning_db > backup.sql

# 압축 백업 (gzip)
pg_dump -U postgres -d learning_db | gzip > backup.sql.gz

# 커스텀 포맷 (권장)
pg_dump -U postgres -d learning_db -F c -f backup.dump

# 디렉토리 포맷 (병렬 백업)
pg_dump -U postgres -d learning_db -F d -f backup_dir -j 4

# 특정 테이블만 백업
pg_dump -U postgres -d learning_db -t users -t orders > tables_backup.sql

# 특정 스키마만 백업
pg_dump -U postgres -d learning_db -n public > schema_backup.sql

# 데이터 제외 (스키마만)
pg_dump -U postgres -d learning_db --schema-only > schema_only.sql

# 데이터만 (스키마 제외)
pg_dump -U postgres -d learning_db --data-only > data_only.sql
```

### pg_dump 옵션 상세

```bash
# 전체 옵션 예시
pg_dump \
  -h localhost \              # 호스트
  -p 5432 \                   # 포트
  -U postgres \               # 사용자
  -d learning_db \            # 데이터베이스
  -F c \                      # 포맷 (c=custom, t=tar, p=plain, d=directory)
  -b \                        # BLOB 포함
  -v \                        # 상세 출력
  -f backup.dump              # 출력 파일

# 특정 테이블 제외
pg_dump -U postgres -d learning_db \
  --exclude-table=logs \
  --exclude-table=temp_* \
  > backup.sql

# 권한 및 소유자 제외
pg_dump -U postgres -d learning_db \
  --no-owner \
  --no-privileges \
  > backup.sql
```

### Docker에서 pg_dump 실행

```bash
# Docker 컨테이너에서 백업
docker exec -t postgres-learning pg_dump -U postgres learning_db > backup.sql

# 압축 백업
docker exec -t postgres-learning pg_dump -U postgres learning_db | gzip > backup.sql.gz

# 커스텀 포맷
docker exec -t postgres-learning pg_dump -U postgres -F c learning_db > backup.dump

# 백업 자동화 (cron)
0 2 * * * docker exec postgres-learning pg_dump -U postgres learning_db | gzip > /backups/db_$(date +\%Y\%m\%d).sql.gz
```

## 🔄 pg_restore 사용법

### 기본 복구

```bash
# 커스텀 포맷 복구
pg_restore -U postgres -d learning_db backup.dump

# 새 데이터베이스에 복구
createdb -U postgres new_db
pg_restore -U postgres -d new_db backup.dump

# 병렬 복구 (빠름)
pg_restore -U postgres -d learning_db -j 4 backup.dump

# 특정 테이블만 복구
pg_restore -U postgres -d learning_db -t users backup.dump

# 기존 데이터 정리 후 복구
pg_restore -U postgres -d learning_db --clean backup.dump

# 테이블 생성 후 데이터 입력
pg_restore -U postgres -d learning_db --create backup.dump
```

### 선택적 복구

```bash
# 스키마만 복구
pg_restore -U postgres -d learning_db --schema-only backup.dump

# 데이터만 복구
pg_restore -U postgres -d learning_db --data-only backup.dump

# 특정 스키마만
pg_restore -U postgres -d learning_db -n public backup.dump

# 테이블 목록 확인
pg_restore --list backup.dump

# 목록 파일로 선택적 복구
pg_restore --list backup.dump > restore_list.txt
# restore_list.txt 편집 (원하는 항목만 남김)
pg_restore -U postgres -d learning_db --use-list=restore_list.txt backup.dump
```

### Docker에서 복구

```bash
# SQL 파일 복구
docker exec -i postgres-learning psql -U postgres -d learning_db < backup.sql

# 압축 파일 복구
gunzip < backup.sql.gz | docker exec -i postgres-learning psql -U postgres -d learning_db

# 커스텀 포맷 복구
docker exec -i postgres-learning pg_restore -U postgres -d learning_db < backup.dump
```

## 🗄️ pg_dumpall (전체 백업)

```bash
# 모든 데이터베이스 + 글로벌 객체
pg_dumpall -U postgres > full_backup.sql

# 글로벌 객체만 (roles, tablespaces 등)
pg_dumpall -U postgres --globals-only > globals.sql

# 역할(사용자)만
pg_dumpall -U postgres --roles-only > roles.sql

# Docker에서 전체 백업
docker exec -t postgres-learning pg_dumpall -U postgres > full_backup.sql
```

## 💾 물리적 백업 (pg_basebackup)

```bash
# 기본 백업
pg_basebackup -U postgres -D /backup/base -F tar -z -P

# 옵션 설명:
# -D: 백업 디렉토리
# -F tar: tar 포맷
# -z: gzip 압축
# -P: 진행률 표시
# -X stream: WAL 파일 포함

# 전체 옵션 예시
pg_basebackup \
  -h localhost \
  -U postgres \
  -D /backup/base_$(date +%Y%m%d) \
  -F tar \
  -z \
  -P \
  -X stream \
  -c fast
```

## 🔄 PITR (Point-in-Time Recovery)

### 1. WAL 아카이빙 설정

```bash
# postgresql.conf 편집
wal_level = replica
archive_mode = on
archive_command = 'cp %p /backup/wal_archive/%f'
max_wal_senders = 3

# Docker Compose에서 설정
# volumes:
#   - ./postgresql.conf:/etc/postgresql/postgresql.conf
```

### 2. 베이스 백업 생성

```bash
pg_basebackup -U postgres -D /backup/base -F tar -z -X stream
```

### 3. 특정 시점으로 복구

```bash
# 1. 데이터 디렉토리 복구
cd /var/lib/postgresql/data
tar xzf /backup/base/base.tar.gz

# 2. recovery.conf 생성 (PostgreSQL 12+는 postgresql.conf)
restore_command = 'cp /backup/wal_archive/%f %p'
recovery_target_time = '2024-11-24 14:30:00'
recovery_target_action = 'promote'

# 3. PostgreSQL 재시작
pg_ctl restart
```

## ☁️ 클라우드 백업 전략

### AWS S3 백업

```bash
# AWS CLI 사용
pg_dump -U postgres -F c learning_db | \
  aws s3 cp - s3://my-backup-bucket/postgres/backup_$(date +%Y%m%d).dump

# 복구
aws s3 cp s3://my-backup-bucket/postgres/backup_20241124.dump - | \
  pg_restore -U postgres -d learning_db

# 정기 백업 스크립트
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BUCKET="s3://my-backup-bucket/postgres"

docker exec postgres-learning pg_dump -U postgres -F c learning_db | \
  gzip | \
  aws s3 cp - ${BUCKET}/backup_${DATE}.dump.gz

# 30일 이상 된 백업 삭제
aws s3 ls ${BUCKET}/ | \
  awk '{print $4}' | \
  while read file; do
    # 삭제 로직
  done
```

### Google Cloud Storage 백업

```bash
# gcloud 사용
pg_dump -U postgres -F c learning_db | \
  gsutil cp - gs://my-backup-bucket/postgres/backup_$(date +%Y%m%d).dump

# 복구
gsutil cat gs://my-backup-bucket/postgres/backup_20241124.dump | \
  pg_restore -U postgres -d learning_db
```

## 🔒 백업 검증

```bash
# 백업 파일 무결성 검사
pg_restore --list backup.dump > /dev/null
echo $?  # 0이면 성공

# 테스트 데이터베이스에 복구 테스트
createdb -U postgres test_restore
pg_restore -U postgres -d test_restore backup.dump
psql -U postgres -d test_restore -c "SELECT COUNT(*) FROM users;"
dropdb -U postgres test_restore

# 백업 자동화 + 검증 스크립트
#!/bin/bash
BACKUP_FILE="backup_$(date +%Y%m%d).dump"

# 백업
pg_dump -U postgres -F c learning_db -f $BACKUP_FILE

# 검증
if pg_restore --list $BACKUP_FILE > /dev/null 2>&1; then
  echo "Backup successful: $BACKUP_FILE"
  # S3 업로드
  aws s3 cp $BACKUP_FILE s3://my-backup-bucket/
else
  echo "Backup failed!"
  exit 1
fi
```

## 📋 백업 전략 권장사항

### 3-2-1 백업 규칙

- **3개의 복사본**: 원본 + 백업 2개
- **2개의 다른 미디어**: 로컬 + 클라우드
- **1개는 오프사이트**: 다른 지역/클라우드

### 백업 주기

```bash
# 일일 백업 (보관: 7일)
0 2 * * * /scripts/daily_backup.sh

# 주간 백업 (보관: 4주)
0 3 * * 0 /scripts/weekly_backup.sh

# 월간 백업 (보관: 12개월)
0 4 1 * * /scripts/monthly_backup.sh

# 백업 스크립트 예시
#!/bin/bash
DATE=$(date +%Y%m%d)
BACKUP_DIR="/backups"
RETENTION_DAYS=7

# 백업 실행
docker exec postgres-learning pg_dump -U postgres -F c learning_db \
  > ${BACKUP_DIR}/daily_${DATE}.dump

# 오래된 백업 삭제
find ${BACKUP_DIR} -name "daily_*.dump" -mtime +${RETENTION_DAYS} -delete

# S3 업로드
aws s3 cp ${BACKUP_DIR}/daily_${DATE}.dump \
  s3://my-backup-bucket/daily/${DATE}.dump

# 알림
echo "Backup completed: daily_${DATE}.dump" | \
  mail -s "PostgreSQL Backup Success" admin@example.com
```

## 🛠️ 실습 과제

파일: [exercises.sh](./exercises.sh)

### 과제 1: 백업 생성
- 전체 데이터베이스 백업
- 특정 테이블만 백업
- 압축 백업 생성

### 과제 2: 복구 연습
- 새 데이터베이스에 복구
- 특정 테이블만 복구
- 데이터 손실 시나리오 복구

### 과제 3: 자동화
- 백업 자동화 스크립트 작성
- 클라우드 업로드 자동화
- 백업 검증 자동화

## ✅ 체크리스트

- [ ] pg_dump로 백업 생성
- [ ] pg_restore로 복구 성공
- [ ] 커스텀/tar/디렉토리 포맷 이해
- [ ] 병렬 백업/복구 실행
- [ ] pg_basebackup 사용
- [ ] WAL 아카이빙 설정
- [ ] PITR 복구 실습
- [ ] 클라우드 백업 구현 (S3 또는 GCS)
- [ ] 백업 자동화 스크립트 작성
- [ ] 백업 검증 프로세스 구축

## 📚 다음 단계

- [03. 클라우드 관리형 DB](../03-cloud-databases/)
- PostgreSQL Backup: https://www.postgresql.org/docs/current/backup.html

---

**완료 예상 시간**: 10-12시간
**난이도**: ⭐⭐⭐☆☆
