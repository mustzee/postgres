# 02. SQL 기초 문법

## 🎯 학습 목표

- DDL (Data Definition Language) 완전 숙달
- DML (Data Manipulation Language) 마스터
- DCL (Data Control Language) 이해
- 기본 쿼리 작성 능력

## 📚 SQL 분류

### DDL (Data Definition Language) - 데이터 정의어
- CREATE, ALTER, DROP, TRUNCATE
- 데이터베이스 구조 정의

### DML (Data Manipulation Language) - 데이터 조작어
- SELECT, INSERT, UPDATE, DELETE
- 데이터 조회 및 수정

### DCL (Data Control Language) - 데이터 제어어
- GRANT, REVOKE
- 권한 관리

### TCL (Transaction Control Language) - 트랜잭션 제어어
- COMMIT, ROLLBACK, SAVEPOINT
- 트랜잭션 관리

## 🔧 DDL: 테이블 생성 및 관리

### CREATE TABLE

```sql
-- 기본 테이블 생성
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    age INTEGER CHECK (age >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 제약조건이 있는 테이블
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    status VARCHAR(20) DEFAULT 'draft',
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- 외래키 제약조건
    CONSTRAINT fk_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    -- 체크 제약조건
    CONSTRAINT check_status
        CHECK (status IN ('draft', 'published', 'archived'))
);

-- 테이블 구조 확인
\d users
\d posts
```

### ALTER TABLE

```sql
-- 컬럼 추가
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- 컬럼 수정
ALTER TABLE users ALTER COLUMN phone TYPE VARCHAR(15);

-- 컬럼 삭제
ALTER TABLE users DROP COLUMN phone;

-- 제약조건 추가
ALTER TABLE users ADD CONSTRAINT check_age CHECK (age >= 18);

-- 제약조건 삭제
ALTER TABLE users DROP CONSTRAINT check_age;

-- 컬럼명 변경
ALTER TABLE users RENAME COLUMN username TO user_name;

-- 테이블명 변경
ALTER TABLE users RENAME TO app_users;
```

### DROP TABLE

```sql
-- 테이블 삭제
DROP TABLE IF EXISTS temp_table;

-- 연관된 객체도 함께 삭제
DROP TABLE IF EXISTS posts CASCADE;

-- 데이터만 삭제 (구조 유지)
TRUNCATE TABLE users;

-- 연관 테이블 데이터도 삭제
TRUNCATE TABLE users CASCADE;
```

## 📊 PostgreSQL 주요 데이터 타입

### 숫자형

```sql
CREATE TABLE data_types_numeric (
    -- 정수형
    small_int SMALLINT,           -- -32768 ~ 32767
    int_val INTEGER,              -- -2147483648 ~ 2147483647
    big_int BIGINT,               -- 매우 큰 정수

    -- 자동 증가 정수
    serial_id SERIAL,             -- 자동 증가 INTEGER
    big_serial_id BIGSERIAL,      -- 자동 증가 BIGINT

    -- 실수형
    decimal_val DECIMAL(10, 2),   -- 고정 소수점 (정확)
    numeric_val NUMERIC(10, 2),   -- DECIMAL과 동일
    real_val REAL,                -- 부동 소수점 (단정밀도)
    double_val DOUBLE PRECISION   -- 부동 소수점 (배정밀도)
);
```

### 문자형

```sql
CREATE TABLE data_types_text (
    -- 고정 길이
    char_col CHAR(10),            -- 항상 10바이트

    -- 가변 길이
    varchar_col VARCHAR(100),     -- 최대 100자

    -- 무제한 길이
    text_col TEXT                 -- 제한 없음 (권장)
);
```

### 날짜/시간형

```sql
CREATE TABLE data_types_datetime (
    date_col DATE,                           -- 날짜만
    time_col TIME,                           -- 시간만
    timestamp_col TIMESTAMP,                 -- 날짜 + 시간
    timestamptz_col TIMESTAMP WITH TIME ZONE, -- 시간대 포함 (권장)
    interval_col INTERVAL                    -- 시간 간격
);
```

### 논리형 & 기타

```sql
CREATE TABLE data_types_misc (
    -- 논리형
    is_active BOOLEAN,            -- TRUE, FALSE, NULL

    -- JSON
    config JSON,                  -- JSON 데이터
    settings JSONB,               -- 바이너리 JSON (인덱싱 가능, 권장)

    -- UUID
    uuid_col UUID,                -- 범용 고유 식별자

    -- 배열
    tags TEXT[],                  -- 문자열 배열
    numbers INTEGER[]             -- 정수 배열
);
```

## 📝 DML: 데이터 조작

### INSERT

```sql
-- 단일 행 삽입
INSERT INTO users (username, email, age)
VALUES ('john_doe', 'john@example.com', 25);

-- 여러 행 삽입
INSERT INTO users (username, email, age)
VALUES
    ('jane_smith', 'jane@example.com', 30),
    ('bob_wilson', 'bob@example.com', 28),
    ('alice_brown', 'alice@example.com', 35);

-- 삽입 후 결과 반환
INSERT INTO users (username, email, age)
VALUES ('charlie', 'charlie@example.com', 22)
RETURNING id, username, created_at;

-- 다른 테이블에서 데이터 복사
INSERT INTO users_backup
SELECT * FROM users WHERE age > 30;

-- 충돌 시 처리 (UPSERT)
INSERT INTO users (username, email, age)
VALUES ('john_doe', 'newemail@example.com', 26)
ON CONFLICT (username)
DO UPDATE SET
    email = EXCLUDED.email,
    age = EXCLUDED.age;
```

### SELECT

```sql
-- 전체 조회
SELECT * FROM users;

-- 특정 컬럼 조회
SELECT username, email FROM users;

-- 조건부 조회
SELECT * FROM users WHERE age >= 25;

-- 정렬
SELECT * FROM users ORDER BY age DESC;

-- 제한
SELECT * FROM users LIMIT 10 OFFSET 5;

-- 중복 제거
SELECT DISTINCT age FROM users;

-- 별칭 사용
SELECT
    username AS "사용자명",
    email AS "이메일",
    age AS "나이"
FROM users;
```

### WHERE 조건절

```sql
-- 비교 연산자
SELECT * FROM users WHERE age > 25;
SELECT * FROM users WHERE age BETWEEN 20 AND 30;

-- 논리 연산자
SELECT * FROM users WHERE age > 25 AND email LIKE '%@example.com';
SELECT * FROM users WHERE age < 20 OR age > 60;
SELECT * FROM users WHERE NOT age = 25;

-- NULL 체크
SELECT * FROM users WHERE phone IS NULL;
SELECT * FROM users WHERE phone IS NOT NULL;

-- 패턴 매칭
SELECT * FROM users WHERE username LIKE 'john%';     -- john으로 시작
SELECT * FROM users WHERE email LIKE '%@gmail.com';  -- @gmail.com으로 끝
SELECT * FROM users WHERE username LIKE '%_doe';     -- _doe로 끝 (_는 한 글자)

-- IN 연산자
SELECT * FROM users WHERE age IN (25, 30, 35);

-- 정규식 (PostgreSQL 특화)
SELECT * FROM users WHERE email ~ '^[a-z]+@example\.com$';
```

### UPDATE

```sql
-- 단순 업데이트
UPDATE users
SET age = 26
WHERE username = 'john_doe';

-- 여러 컬럼 업데이트
UPDATE users
SET
    email = 'newemail@example.com',
    age = age + 1
WHERE id = 1;

-- 조건부 업데이트
UPDATE users
SET age = age + 1
WHERE created_at < NOW() - INTERVAL '1 year';

-- 업데이트 후 결과 반환
UPDATE users
SET age = 30
WHERE username = 'john_doe'
RETURNING *;
```

### DELETE

```sql
-- 조건부 삭제
DELETE FROM users WHERE age < 18;

-- 삭제 후 결과 반환
DELETE FROM users
WHERE created_at < NOW() - INTERVAL '1 year'
RETURNING id, username;

-- 전체 삭제 (주의!)
DELETE FROM users;  -- 느림, 트랜잭션 로그 기록
TRUNCATE users;     -- 빠름, 즉시 삭제
```

## 📊 기본 함수

### 집계 함수

```sql
-- COUNT: 개수
SELECT COUNT(*) FROM users;
SELECT COUNT(DISTINCT age) FROM users;

-- SUM: 합계
SELECT SUM(age) FROM users;

-- AVG: 평균
SELECT AVG(age) FROM users;
SELECT ROUND(AVG(age), 2) FROM users;

-- MIN/MAX: 최소/최대
SELECT MIN(age), MAX(age) FROM users;

-- GROUP BY와 함께
SELECT
    age,
    COUNT(*) as user_count
FROM users
GROUP BY age
ORDER BY age;

-- HAVING: 그룹화 후 조건
SELECT
    age,
    COUNT(*) as count
FROM users
GROUP BY age
HAVING COUNT(*) > 1;
```

### 문자열 함수

```sql
-- 연결
SELECT username || ' - ' || email AS user_info FROM users;
SELECT CONCAT(username, ' - ', email) FROM users;

-- 대소문자 변환
SELECT UPPER(username), LOWER(email) FROM users;

-- 공백 제거
SELECT TRIM('  hello  ');
SELECT LTRIM('  hello');
SELECT RTRIM('hello  ');

-- 길이
SELECT LENGTH(username) FROM users;

-- 부분 문자열
SELECT SUBSTRING(email FROM 1 FOR 10) FROM users;
SELECT LEFT(username, 5), RIGHT(username, 3) FROM users;

-- 치환
SELECT REPLACE(email, '@example.com', '@test.com') FROM users;
```

### 날짜/시간 함수

```sql
-- 현재 시간
SELECT NOW();
SELECT CURRENT_DATE;
SELECT CURRENT_TIME;
SELECT CURRENT_TIMESTAMP;

-- 날짜 연산
SELECT NOW() + INTERVAL '1 day';
SELECT NOW() - INTERVAL '1 week';
SELECT NOW() + INTERVAL '1 month';

-- 날짜 추출
SELECT EXTRACT(YEAR FROM created_at) FROM users;
SELECT EXTRACT(MONTH FROM created_at) FROM users;
SELECT DATE_PART('day', created_at) FROM users;

-- 날짜 형식화
SELECT TO_CHAR(created_at, 'YYYY-MM-DD') FROM users;
SELECT TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') FROM users;

-- 나이 계산
SELECT AGE(CURRENT_DATE, created_at) FROM users;
```

## 📝 실습 과제

파일: [exercises.sql](./exercises.sql)

### 과제 1: 테이블 생성

회사의 직원 관리 시스템을 만드세요.

### 과제 2: 데이터 삽입

최소 10명의 직원 데이터를 삽입하세요.

### 과제 3: 쿼리 작성

다양한 조건으로 데이터를 조회하세요.

## ✅ 체크리스트

- [ ] CREATE TABLE로 3개 이상 테이블 생성
- [ ] ALTER TABLE로 컬럼 추가/수정/삭제
- [ ] 주요 데이터 타입 5가지 이상 사용
- [ ] INSERT 10개 이상 실행
- [ ] SELECT with WHERE, ORDER BY, LIMIT 작성
- [ ] UPDATE와 DELETE 실행
- [ ] 집계 함수 5가지 사용
- [ ] GROUP BY와 HAVING 사용
- [ ] 문자열 함수 3가지 사용
- [ ] 날짜 함수 3가지 사용

---

**완료 예상 시간**: 8-10시간
**난이도**: ⭐⭐☆☆☆
