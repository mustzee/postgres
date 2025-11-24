# PostgreSQL 마스터 학습 로드맵 🚀

클라우드 엔지니어를 위한 체계적인 PostgreSQL 학습 프로젝트

## 🎯 학습 목표

1. **PostgreSQL 완전 마스터** - 클라우드 환경에서 가장 널리 사용되는 DB
2. **SQL 기초부터 고급까지** - 실무에서 바로 쓰는 쿼리 능력
3. **클라우드 DB 운영** - AWS RDS, Cloud SQL, Azure Database
4. **현대적 데이터 아키텍처** - NoSQL, 데이터 파이프라인

## 📚 학습 단계

### Phase 1: 기초 다지기 (1-2개월)
- [01. 설치 및 환경 구성](./phase1-basics/01-installation/)
- [02. SQL 기초 문법](./phase1-basics/02-sql-fundamentals/)
- [03. 데이터 모델링](./phase1-basics/03-data-modeling/)
- [실습 예제](./phase1-basics/exercises/)

### Phase 2: 실무 적용 (2-3개월)
- [01. 성능 최적화](./phase2-intermediate/01-performance-optimization/)
- [02. 백업/복구](./phase2-intermediate/02-backup-recovery/)
- [03. 클라우드 관리형 DB](./phase2-intermediate/03-cloud-databases/)
- [실습 예제](./phase2-intermediate/exercises/)

### Phase 3: 고도화 (3-4개월)
- [01. NoSQL 하이브리드](./phase3-advanced/01-nosql-hybrid/)
- [02. 데이터 파이프라인](./phase3-advanced/02-data-pipelines/)
- [03. 모니터링 자동화](./phase3-advanced/03-monitoring-automation/)
- [실습 예제](./phase3-advanced/exercises/)

## 🚀 빠른 시작

### 1. PostgreSQL 환경 시작

```bash
# Docker Compose로 PostgreSQL + pgAdmin 실행
docker-compose up -d

# 상태 확인
docker-compose ps

# PostgreSQL 접속
docker exec -it postgres-learning psql -U postgres -d learning_db
```

### 2. pgAdmin 접속

- URL: http://localhost:5050
- Email: admin@postgres.local
- Password: admin

### 3. PostgreSQL 서버 연결 (pgAdmin에서)

- Host: postgres
- Port: 5432
- Username: postgres
- Password: postgres

## 📖 학습 방법

1. **각 Phase를 순서대로 학습**
   - README.md를 읽고 개념 이해
   - 예제 SQL 파일 직접 실행
   - 연습 문제 풀이

2. **실습 중심 학습**
   - 모든 SQL 쿼리 직접 작성하고 실행
   - 결과를 분석하고 이해
   - 다양한 케이스로 실험

3. **프로젝트 적용**
   - Epicodix 프로젝트에 DB 연동
   - 실무 데이터 모델링
   - 성능 최적화 적용

## 🛠️ 필수 도구

- Docker & Docker Compose
- psql (PostgreSQL CLI)
- pgAdmin 또는 DBeaver
- Git

## 📋 체크리스트

### Phase 1 ✅
- [ ] PostgreSQL 설치 및 기본 명령어
- [ ] DDL: CREATE, ALTER, DROP
- [ ] DML: SELECT, INSERT, UPDATE, DELETE
- [ ] 기본 JOIN (INNER, LEFT, RIGHT)
- [ ] WHERE, GROUP BY, HAVING
- [ ] 기본 함수 (집계, 문자열, 날짜)
- [ ] 서브쿼리 기초
- [ ] 데이터 타입 이해
- [ ] 정규화 (1NF ~ 3NF)

### Phase 2 ✅
- [ ] 고급 JOIN (FULL OUTER, CROSS, SELF)
- [ ] 윈도우 함수 (ROW_NUMBER, RANK, PARTITION)
- [ ] CTE (Common Table Expression)
- [ ] 인덱스 생성 및 분석
- [ ] EXPLAIN ANALYZE 이해
- [ ] 트랜잭션과 ACID
- [ ] pg_dump, pg_restore
- [ ] AWS RDS 실습
- [ ] Connection Pooling

### Phase 3 ✅
- [ ] PostgreSQL JSON/JSONB 활용
- [ ] 파티셔닝 (Range, List, Hash)
- [ ] Replication 설정
- [ ] PostgreSQL + Redis 연동
- [ ] Apache Airflow 기초
- [ ] Prometheus + Grafana 모니터링
- [ ] Terraform으로 DB 인프라 코드화

## 📚 추천 학습 리소스

### 공식 문서
- [PostgreSQL Official Docs](https://www.postgresql.org/docs/)
- [PostgreSQL Tutorial](https://www.postgresqltutorial.com/)

### 클라우드 교육
- [AWS RDS PostgreSQL](https://aws.amazon.com/rds/postgresql/)
- [Google Cloud SQL](https://cloud.google.com/sql/docs/postgres)
- [Azure Database for PostgreSQL](https://azure.microsoft.com/en-us/services/postgresql/)

### 실습 플랫폼
- [pgExercises](https://pgexercises.com/)
- [SQL Bolt](https://sqlbolt.com/)
- [LeetCode Database](https://leetcode.com/problemset/database/)

## 💡 학습 팁

1. **PostgreSQL 하나를 완전히 마스터하면 다른 DB도 쉽게 익힐 수 있습니다**
2. **클라우드 엔지니어는 DB 관리와 자동화가 핵심** - 운영 관점에서 학습하세요
3. **매일 조금씩 실습** - 하루 30분이라도 SQL 쿼리 작성
4. **실제 프로젝트에 적용** - Epicodix에 DB 연동하며 학습
5. **성능을 항상 고려** - EXPLAIN ANALYZE 습관화

## 🎓 인증 및 자격증 (선택)

- AWS Certified Database - Specialty
- Google Cloud Professional Data Engineer
- PostgreSQL CE (Certified Engineer)

## 📞 도움말

각 Phase 디렉토리의 README.md를 참고하세요!

---

**시작일**: 2025-11-24
**목표**: 6개월 내 PostgreSQL 마스터
