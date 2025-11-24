# 01. PostgreSQL 설치 및 환경 구성

## 🎯 학습 목표

- PostgreSQL 설치 및 기본 설정
- psql CLI 사용법 익히기
- pgAdmin을 통한 GUI 관리
- 기본 데이터베이스 작업

## 📋 사전 준비

- Docker 및 Docker Compose 설치
- 터미널 기본 명령어 이해
- 텍스트 에디터 (VSCode 등)

## 🚀 설치 방법

### 1. Docker Compose 사용 (권장)

```bash
# 프로젝트 루트에서 실행
docker-compose up -d

# 컨테이너 상태 확인
docker-compose ps

# 로그 확인
docker-compose logs -f postgres
```

### 2. PostgreSQL 컨테이너 접속

```bash
# psql 접속
docker exec -it postgres-learning psql -U postgres -d learning_db

# Bash 접속
docker exec -it postgres-learning bash
```

### 3. 환경 정보

- **Host**: localhost
- **Port**: 5432
- **Database**: learning_db
- **User**: postgres
- **Password**: postgres

## 🔧 psql 기본 명령어

### 메타 명령어 (\ 시작)

```sql
\l              -- 모든 데이터베이스 목록
\c database     -- 데이터베이스 연결
\dt             -- 테이블 목록
\d table_name   -- 테이블 구조 확인
\du             -- 사용자 목록
\df             -- 함수 목록
\dn             -- 스키마 목록
\x              -- 확장 출력 모드 토글
\q              -- psql 종료
\?              -- 도움말
\h SQL_COMMAND  -- SQL 명령어 도움말 (예: \h SELECT)
```

### 첫 번째 명령어 실행

```sql
-- PostgreSQL 버전 확인
SELECT version();

-- 현재 시간 확인
SELECT NOW();

-- 현재 데이터베이스 확인
SELECT current_database();

-- 현재 사용자 확인
SELECT current_user;
```

## 📊 pgAdmin 사용법

### 1. 접속

- URL: http://localhost:5050
- Email: admin@postgres.local
- Password: admin

### 2. 서버 등록

1. 좌측 "Servers" 우클릭 → "Register" → "Server"
2. General 탭:
   - Name: Local PostgreSQL
3. Connection 탭:
   - Host: postgres
   - Port: 5432
   - Username: postgres
   - Password: postgres
4. Save

### 3. 주요 기능

- **Dashboard**: 서버 상태 모니터링
- **Query Tool**: SQL 쿼리 실행
- **Tables**: 테이블 관리
- **Schemas**: 스키마 관리
- **Backup/Restore**: 백업 및 복원

## 🛠️ 첫 데이터베이스 생성

### 1. psql에서 생성

```sql
-- 새 데이터베이스 생성
CREATE DATABASE my_first_db;

-- 데이터베이스 목록 확인
\l

-- 새 데이터베이스로 연결
\c my_first_db

-- 현재 연결 정보 확인
\conninfo
```

### 2. 새 사용자 생성

```sql
-- 새 사용자 생성
CREATE USER dev_user WITH PASSWORD 'dev_password';

-- 사용자에게 권한 부여
GRANT ALL PRIVILEGES ON DATABASE my_first_db TO dev_user;

-- 사용자 목록 확인
\du
```

### 3. 스키마 생성

```sql
-- 새 스키마 생성
CREATE SCHEMA app_schema;

-- 스키마 목록 확인
\dn

-- 기본 스키마 설정
SET search_path TO app_schema, public;

-- 현재 search_path 확인
SHOW search_path;
```

## 📝 실습 과제

### 과제 1: 환경 설정 확인

```sql
-- 1. PostgreSQL 버전 확인
SELECT version();

-- 2. 현재 데이터베이스와 사용자 확인
SELECT current_database(), current_user;

-- 3. 모든 데이터베이스 목록 조회
SELECT datname FROM pg_database;

-- 4. 현재 시스템 시간 확인
SELECT NOW(), CURRENT_DATE, CURRENT_TIME;
```

### 과제 2: 데이터베이스 생성 및 관리

```sql
-- 1. 'practice_db' 데이터베이스 생성
CREATE DATABASE practice_db;

-- 2. practice_db로 연결

-- 3. 'practice_user' 사용자 생성 (비밀번호: practice123)
CREATE USER practice_user WITH PASSWORD 'practice123';

-- 4. practice_user에게 practice_db 권한 부여
GRANT ALL PRIVILEGES ON DATABASE practice_db TO practice_user;
```

### 과제 3: pgAdmin 실습

1. pgAdmin에서 로컬 서버 등록
2. Query Tool로 첫 번째 쿼리 실행
3. Dashboard에서 서버 상태 확인
4. 새 데이터베이스 생성 (GUI 사용)

## 🔍 트러블슈팅

### 컨테이너가 시작되지 않을 때

```bash
# 컨테이너 로그 확인
docker-compose logs postgres

# 컨테이너 재시작
docker-compose restart postgres

# 완전 재시작
docker-compose down
docker-compose up -d
```

### 포트가 이미 사용 중일 때

```bash
# 5432 포트 사용 확인
lsof -i :5432

# docker-compose.yml에서 포트 변경
# ports:
#   - "5433:5432"
```

### 연결 오류 발생 시

```bash
# PostgreSQL이 준비될 때까지 대기
docker-compose up -d
sleep 10
docker exec -it postgres-learning psql -U postgres
```

## 📚 다음 단계

- [02. SQL 기초 문법](../02-sql-fundamentals/)
- PostgreSQL 공식 문서: https://www.postgresql.org/docs/current/tutorial-start.html

## ✅ 체크리스트

- [ ] Docker Compose로 PostgreSQL 실행
- [ ] psql 접속 성공
- [ ] pgAdmin 접속 및 서버 등록
- [ ] 기본 메타 명령어 5개 이상 실행
- [ ] 첫 데이터베이스 생성
- [ ] 새 사용자 생성 및 권한 부여
- [ ] Query Tool에서 SELECT 쿼리 실행

---

**완료 예상 시간**: 2-3시간
**난이도**: ⭐☆☆☆☆
