# PostgreSQL SQL Cheatsheet

## 🔧 psql 메타 명령어

```sql
\l                  -- 데이터베이스 목록
\c dbname           -- 데이터베이스 연결
\dt                 -- 테이블 목록
\d tablename        -- 테이블 구조
\du                 -- 사용자 목록
\df                 -- 함수 목록
\di                 -- 인덱스 목록
\dn                 -- 스키마 목록
\dv                 -- 뷰 목록
\x                  -- 확장 출력 토글
\timing             -- 쿼리 실행 시간 표시
\! command          -- 셸 명령어 실행
\q                  -- 종료
```

## 📊 DDL (Data Definition Language)

### 데이터베이스

```sql
-- 생성
CREATE DATABASE mydb;
CREATE DATABASE mydb ENCODING 'UTF8';

-- 삭제
DROP DATABASE mydb;

-- 변경
ALTER DATABASE mydb RENAME TO newdb;
```

### 테이블

```sql
-- 생성
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 수정
ALTER TABLE users ADD COLUMN age INTEGER;
ALTER TABLE users DROP COLUMN age;
ALTER TABLE users ALTER COLUMN name TYPE TEXT;
ALTER TABLE users RENAME COLUMN name TO username;
ALTER TABLE users RENAME TO app_users;

-- 삭제
DROP TABLE users;
DROP TABLE IF EXISTS users CASCADE;
TRUNCATE users;  -- 데이터만 삭제
```

### 제약조건

```sql
-- PRIMARY KEY
CREATE TABLE t (id SERIAL PRIMARY KEY);
ALTER TABLE t ADD PRIMARY KEY (id);

-- FOREIGN KEY
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE
);

-- UNIQUE
ALTER TABLE users ADD CONSTRAINT unique_email UNIQUE (email);

-- CHECK
ALTER TABLE users ADD CONSTRAINT check_age CHECK (age >= 0);

-- NOT NULL
ALTER TABLE users ALTER COLUMN email SET NOT NULL;
```

### 인덱스

```sql
-- 생성
CREATE INDEX idx_users_email ON users(email);
CREATE UNIQUE INDEX idx_unique_email ON users(email);
CREATE INDEX idx_lower_email ON users(LOWER(email));
CREATE INDEX idx_users_partial ON users(email) WHERE is_active = TRUE;

-- 삭제
DROP INDEX idx_users_email;

-- 재구축
REINDEX INDEX idx_users_email;
REINDEX TABLE users;
```

## 📝 DML (Data Manipulation Language)

### INSERT

```sql
-- 단일 삽입
INSERT INTO users (name, email) VALUES ('John', 'john@example.com');

-- 다중 삽입
INSERT INTO users (name, email) VALUES
    ('Alice', 'alice@example.com'),
    ('Bob', 'bob@example.com');

-- 반환
INSERT INTO users (name, email)
VALUES ('Charlie', 'charlie@example.com')
RETURNING id, created_at;

-- UPSERT
INSERT INTO users (id, name, email)
VALUES (1, 'John', 'john@new.com')
ON CONFLICT (id)
DO UPDATE SET email = EXCLUDED.email;
```

### SELECT

```sql
-- 기본
SELECT * FROM users;
SELECT name, email FROM users;
SELECT DISTINCT age FROM users;

-- WHERE
SELECT * FROM users WHERE age > 25;
SELECT * FROM users WHERE name LIKE 'J%';
SELECT * FROM users WHERE age BETWEEN 20 AND 30;
SELECT * FROM users WHERE age IN (25, 30, 35);
SELECT * FROM users WHERE email IS NULL;

-- ORDER BY
SELECT * FROM users ORDER BY created_at DESC;
SELECT * FROM users ORDER BY age DESC, name ASC;

-- LIMIT & OFFSET
SELECT * FROM users LIMIT 10;
SELECT * FROM users LIMIT 10 OFFSET 20;

-- 집계
SELECT COUNT(*) FROM users;
SELECT AVG(age) FROM users;
SELECT MAX(age), MIN(age) FROM users;

-- GROUP BY
SELECT age, COUNT(*) FROM users GROUP BY age;
SELECT age, AVG(salary) FROM users GROUP BY age HAVING AVG(salary) > 50000;
```

### UPDATE

```sql
-- 기본
UPDATE users SET age = 30 WHERE id = 1;

-- 다중 컬럼
UPDATE users SET age = 30, email = 'new@email.com' WHERE id = 1;

-- 연산
UPDATE users SET age = age + 1 WHERE created_at < NOW() - INTERVAL '1 year';

-- 반환
UPDATE users SET age = 30 WHERE id = 1 RETURNING *;
```

### DELETE

```sql
-- 조건부 삭제
DELETE FROM users WHERE age < 18;

-- 반환
DELETE FROM users WHERE id = 1 RETURNING *;

-- 전체 삭제
DELETE FROM users;
TRUNCATE users;
```

## 🔗 JOIN

```sql
-- INNER JOIN
SELECT u.name, o.total
FROM users u
INNER JOIN orders o ON u.id = o.user_id;

-- LEFT JOIN
SELECT u.name, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.name;

-- RIGHT JOIN
SELECT * FROM users u
RIGHT JOIN orders o ON u.id = o.user_id;

-- FULL OUTER JOIN
SELECT * FROM users u
FULL OUTER JOIN orders o ON u.id = o.user_id;

-- CROSS JOIN
SELECT * FROM users CROSS JOIN products;

-- SELF JOIN
SELECT e.name as employee, m.name as manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;
```

## 🪟 윈도우 함수

```sql
-- ROW_NUMBER
SELECT name, age, ROW_NUMBER() OVER (ORDER BY age DESC) as rank
FROM users;

-- RANK (동점 처리)
SELECT name, score, RANK() OVER (ORDER BY score DESC) as rank
FROM users;

-- PARTITION BY
SELECT
    department,
    name,
    salary,
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) as dept_rank
FROM employees;

-- LAG/LEAD
SELECT
    date,
    sales,
    LAG(sales) OVER (ORDER BY date) as prev_sales,
    LEAD(sales) OVER (ORDER BY date) as next_sales
FROM daily_sales;
```

## 📦 CTE (Common Table Expression)

```sql
-- 기본
WITH recent_users AS (
    SELECT * FROM users WHERE created_at > NOW() - INTERVAL '7 days'
)
SELECT * FROM recent_users;

-- 여러 CTE
WITH
    active_users AS (SELECT * FROM users WHERE is_active = TRUE),
    recent_orders AS (SELECT * FROM orders WHERE created_at > NOW() - INTERVAL '30 days')
SELECT u.name, COUNT(o.id) as order_count
FROM active_users u
LEFT JOIN recent_orders o ON u.id = o.user_id
GROUP BY u.id, u.name;

-- 재귀 CTE
WITH RECURSIVE tree AS (
    SELECT id, name, parent_id, 1 as level
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    SELECT c.id, c.name, c.parent_id, t.level + 1
    FROM categories c
    JOIN tree t ON c.parent_id = t.id
)
SELECT * FROM tree;
```

## 📊 주요 함수

### 문자열 함수

```sql
UPPER('hello')                      -- HELLO
LOWER('HELLO')                      -- hello
LENGTH('hello')                     -- 5
SUBSTRING('hello' FROM 1 FOR 3)     -- hel
CONCAT('hello', ' ', 'world')       -- hello world
'hello' || ' ' || 'world'           -- hello world
REPLACE('hello', 'l', 'r')          -- herro
TRIM('  hello  ')                   -- hello
LEFT('hello', 2)                    -- he
RIGHT('hello', 2)                   -- lo
```

### 숫자 함수

```sql
ROUND(3.14159, 2)                   -- 3.14
CEIL(3.14)                          -- 4
FLOOR(3.14)                         -- 3
ABS(-5)                             -- 5
POWER(2, 3)                         -- 8
SQRT(16)                            -- 4
```

### 날짜/시간 함수

```sql
NOW()                                           -- 현재 시간
CURRENT_DATE                                    -- 현재 날짜
CURRENT_TIME                                    -- 현재 시간
CURRENT_TIMESTAMP                               -- 현재 타임스탬프
AGE(CURRENT_DATE, '2020-01-01')                -- 기간
EXTRACT(YEAR FROM NOW())                        -- 연도
DATE_PART('month', NOW())                       -- 월
TO_CHAR(NOW(), 'YYYY-MM-DD')                   -- 형식화
NOW() + INTERVAL '1 day'                        -- 1일 후
NOW() - INTERVAL '1 week'                       -- 1주 전
```

### JSONB 함수

```sql
data->'key'                         -- JSON 값
data->>'key'                        -- 텍스트 값
data @> '{"key": "value"}'          -- 포함 확인
data ? 'key'                        -- 키 존재 확인
jsonb_set(data, '{key}', '"new"')   -- 값 설정
data - 'key'                        -- 키 삭제
jsonb_array_elements(data)          -- 배열 전개
```

## 🔒 트랜잭션

```sql
-- 기본
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;

-- 롤백
BEGIN;
UPDATE users SET age = 30;
ROLLBACK;  -- 변경사항 취소

-- SAVEPOINT
BEGIN;
UPDATE users SET age = age + 1;
SAVEPOINT sp1;
DELETE FROM users WHERE age < 18;
ROLLBACK TO sp1;  -- SAVEPOINT로 롤백
COMMIT;
```

## 🔍 성능 최적화

```sql
-- EXPLAIN
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';

-- EXPLAIN ANALYZE (실제 실행)
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';

-- VACUUM
VACUUM users;
VACUUM ANALYZE users;

-- 통계 업데이트
ANALYZE users;
```

## 🛡️ 권한 관리

```sql
-- 사용자 생성
CREATE USER myuser WITH PASSWORD 'password';

-- 권한 부여
GRANT SELECT, INSERT, UPDATE ON users TO myuser;
GRANT ALL PRIVILEGES ON DATABASE mydb TO myuser;

-- 권한 회수
REVOKE INSERT ON users FROM myuser;

-- 역할 생성
CREATE ROLE readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
GRANT readonly TO myuser;
```

---

**팁**: 이 cheatsheet를 자주 참고하세요!
