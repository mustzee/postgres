# PostgreSQL 학습 빠른 시작 가이드 🚀

## 1️⃣ 환경 시작 (2분)

```bash
# PostgreSQL + pgAdmin 실행
docker-compose up -d

# 상태 확인
docker-compose ps

# PostgreSQL 준비될 때까지 대기
sleep 10
```

## 2️⃣ PostgreSQL 접속 (1분)

### 방법 1: psql (CLI)

```bash
# Docker 컨테이너 접속
docker exec -it postgres-learning psql -U postgres -d learning_db

# 샘플 데이터 로드
\i /docker-entrypoint-initdb.d/01-create-sample-data.sql
```

### 방법 2: pgAdmin (GUI)

1. 브라우저에서 http://localhost:5050 접속
2. 로그인:
   - Email: `admin@postgres.local`
   - Password: `admin`
3. 서버 등록:
   - Host: `postgres`
   - Port: `5432`
   - Username: `postgres`
   - Password: `postgres`

## 3️⃣ 첫 번째 쿼리 (1분)

```sql
-- 현재 버전 확인
SELECT version();

-- 샘플 데이터 확인
SELECT * FROM departments;
SELECT * FROM employees LIMIT 5;

-- 부서별 통계
SELECT * FROM department_stats;

-- 간단한 JOIN
SELECT
    e.first_name || ' ' || e.last_name as name,
    d.name as department,
    e.salary
FROM employees e
JOIN departments d ON e.department_id = d.id
ORDER BY e.salary DESC
LIMIT 5;
```

## 4️⃣ 학습 시작

### Phase 1: 기초 (지금 시작!)

```bash
# 설치 가이드 읽기
cat phase1-basics/01-installation/README.md

# SQL 기초 학습
cat phase1-basics/02-sql-fundamentals/README.md

# 실습 문제 풀기
docker exec -i postgres-learning psql -U postgres -d learning_db < phase1-basics/02-sql-fundamentals/exercises.sql
```

### 치트시트 활용

```bash
# SQL 치트시트 보기
cat resources/cheatsheets/sql-cheatsheet.md

# 자주 찾아보세요!
```

## 5️⃣ 일일 학습 루틴

### 추천 학습 패턴 (하루 1시간)

1. **개념 학습** (20분): README.md 읽기
2. **실습** (30분): 예제 SQL 직접 작성
3. **복습** (10분): 치트시트로 정리

### 주간 목표

- **Week 1-2**: Phase 1 (SQL 기초)
- **Week 3-4**: Phase 1 완료 (데이터 모델링)
- **Week 5-8**: Phase 2 (성능 최적화, 클라우드)
- **Week 9-16**: Phase 3 (고급 주제)

## 🎯 오늘 해야 할 일

- [ ] Docker 환경 시작
- [ ] PostgreSQL 접속 성공
- [ ] 샘플 쿼리 5개 실행
- [ ] Phase 1-01 README 읽기
- [ ] psql 메타 명령어 10개 실습

## 💡 학습 팁

1. **매일 조금씩**: 하루 30분이라도 꾸준히
2. **손으로 타이핑**: 복붙 금지! 직접 타이핑하며 학습
3. **실제 데이터**: Epicodix 프로젝트에 적용
4. **치트시트 활용**: 자주 참고하며 암기
5. **EXPLAIN 습관화**: 모든 SELECT에 EXPLAIN 붙이기

## 🆘 문제 해결

### 컨테이너가 시작되지 않을 때

```bash
# 로그 확인
docker-compose logs postgres

# 재시작
docker-compose down
docker-compose up -d
```

### 연결이 안 될 때

```bash
# 컨테이너 상태 확인
docker ps

# PostgreSQL 준비 확인
docker exec postgres-learning pg_isready -U postgres
```

### 데이터가 없을 때

```bash
# 샘플 데이터 다시 로드
docker exec -i postgres-learning psql -U postgres -d learning_db < init-scripts/01-create-sample-data.sql
```

## 📚 다음 단계

1. [Phase 1: 기초](./phase1-basics/)
2. [Phase 2: 중급](./phase2-intermediate/)
3. [Phase 3: 고급](./phase3-advanced/)
4. [SQL Cheatsheet](./resources/cheatsheets/sql-cheatsheet.md)

---

**시작 날짜를 기록하세요**: _______________

**목표 완료 날짜**: _______________ (6개월 후)

**화이팅! 🚀**
