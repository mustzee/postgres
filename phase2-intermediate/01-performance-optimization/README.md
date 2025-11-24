# 01. 성능 최적화

## 🎯 학습 목표

- 쿼리 성능 분석 (EXPLAIN ANALYZE)
- 인덱스 전략 수립
- 쿼리 최적화 기법
- N+1 문제 해결

## 📊 EXPLAIN ANALYZE 마스터

### EXPLAIN vs EXPLAIN ANALYZE

```sql
-- EXPLAIN: 실행 계획만 확인 (실제 실행 안 함)
EXPLAIN
SELECT * FROM users WHERE email = 'test@example.com';

-- EXPLAIN ANALYZE: 실제 실행하고 통계 수집
EXPLAIN ANALYZE
SELECT * FROM users WHERE email = 'test@example.com';

-- 더 자세한 정보
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT * FROM users WHERE email = 'test@example.com';
```

### 실행 계획 읽는 법

```sql
-- 예시 쿼리
EXPLAIN ANALYZE
SELECT u.name, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.created_at > '2024-01-01'
GROUP BY u.id, u.name
ORDER BY order_count DESC
LIMIT 10;

/*
실행 계획 해석:
- Seq Scan: 전체 테이블 스캔 (느림) ❌
- Index Scan: 인덱스 사용 (빠름) ✅
- Index Only Scan: 인덱스만으로 데이터 조회 (가장 빠름) ✅✅
- Bitmap Index Scan: 여러 인덱스 조합
- Hash Join: 해시 조인
- Nested Loop: 중첩 루프 조인
- Cost: 예상 비용 (낮을수록 좋음)
- Rows: 예상 행 수
- Actual time: 실제 소요 시간
- Planning Time: 계획 수립 시간
- Execution Time: 실제 실행 시간
*/
```

## 🚀 인덱스 최적화

### B-Tree 인덱스 (기본)

```sql
-- 단일 컬럼 인덱스
CREATE INDEX idx_users_email ON users(email);

-- 복합 인덱스 (순서 중요!)
CREATE INDEX idx_orders_user_date ON orders(user_id, created_at);

-- 이 인덱스로 가능한 쿼리:
-- ✅ WHERE user_id = 1
-- ✅ WHERE user_id = 1 AND created_at > '2024-01-01'
-- ❌ WHERE created_at > '2024-01-01' (user_id 없이는 인덱스 미사용)
```

### 부분 인덱스 (Partial Index)

```sql
-- 활성 사용자만 인덱싱
CREATE INDEX idx_active_users
ON users(email)
WHERE is_active = TRUE;

-- NULL이 아닌 값만 인덱싱
CREATE INDEX idx_verified_emails
ON users(email)
WHERE email_verified_at IS NOT NULL;

-- 최근 주문만 인덱싱
CREATE INDEX idx_recent_orders
ON orders(created_at)
WHERE created_at > '2024-01-01';
```

### 표현식 인덱스

```sql
-- 소문자 변환 인덱스
CREATE INDEX idx_users_lower_email ON users(LOWER(email));

-- 이제 이 쿼리가 인덱스 사용:
SELECT * FROM users WHERE LOWER(email) = 'test@example.com';

-- JSON 필드 인덱싱
CREATE INDEX idx_user_preferences
ON users((preferences->>'theme'));
```

### 전문 검색 인덱스 (Full-Text Search)

```sql
-- GIN 인덱스로 전문 검색
CREATE INDEX idx_products_search
ON products
USING GIN (to_tsvector('english', name || ' ' || description));

-- 전문 검색 쿼리
SELECT * FROM products
WHERE to_tsvector('english', name || ' ' || description)
      @@ to_tsquery('english', 'laptop & gaming');

-- 한글 전문 검색 (pg_trgm 확장 사용)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX idx_products_name_trgm
ON products
USING GIN (name gin_trgm_ops);

-- 유사 검색
SELECT * FROM products
WHERE name % '노트북';  -- 유사도 검색

SELECT * FROM products
WHERE name ILIKE '%노트북%';  -- 부분 일치 (인덱스 사용)
```

### 멀티컬럼 인덱스 전략

```sql
-- ❌ 나쁜 예: 개별 인덱스
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_date ON orders(created_at);

-- ✅ 좋은 예: 복합 인덱스
CREATE INDEX idx_orders_lookup
ON orders(user_id, status, created_at);

-- 커버링 인덱스 (Index-Only Scan)
CREATE INDEX idx_orders_covering
ON orders(user_id, status, created_at)
INCLUDE (total_amount);  -- PostgreSQL 11+
```

## 🔍 쿼리 최적화 기법

### JOIN 최적화

```sql
-- ❌ 비효율적: 서브쿼리
SELECT
    u.name,
    (SELECT COUNT(*) FROM orders WHERE user_id = u.id) as order_count
FROM users u;

-- ✅ 효율적: JOIN 사용
SELECT
    u.name,
    COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.name;

-- ✅ 더 효율적: 필터링 먼저
SELECT
    u.name,
    COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
    AND o.status = 'completed'  -- JOIN 시점에 필터링
WHERE u.is_active = TRUE
GROUP BY u.id, u.name;
```

### 서브쿼리 vs JOIN

```sql
-- ❌ 느린 서브쿼리
SELECT * FROM products
WHERE category_id IN (
    SELECT id FROM categories WHERE name LIKE 'Electronics%'
);

-- ✅ 빠른 JOIN
SELECT p.*
FROM products p
JOIN categories c ON p.category_id = c.id
WHERE c.name LIKE 'Electronics%';

-- ✅ EXISTS 사용 (존재 여부만 확인)
SELECT * FROM users u
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.user_id = u.id
      AND o.created_at > NOW() - INTERVAL '1 month'
);
```

### LIMIT와 OFFSET 최적화

```sql
-- ❌ 느린 OFFSET (큰 오프셋)
SELECT * FROM products
ORDER BY id
LIMIT 20 OFFSET 10000;  -- 10000개 읽고 버림

-- ✅ 키셋 페이지네이션 (Keyset Pagination)
SELECT * FROM products
WHERE id > 10000  -- 마지막 ID 기준
ORDER BY id
LIMIT 20;

-- 양방향 페이지네이션
-- 다음 페이지
SELECT * FROM products
WHERE id > :last_id
ORDER BY id ASC
LIMIT 20;

-- 이전 페이지
SELECT * FROM products
WHERE id < :first_id
ORDER BY id DESC
LIMIT 20;
```

### N+1 문제 해결

```sql
-- ❌ N+1 문제 (ORM에서 흔함)
-- 1. 사용자 목록 조회 (1 query)
SELECT * FROM users LIMIT 10;
-- 2. 각 사용자의 주문 조회 (N queries)
SELECT * FROM orders WHERE user_id = 1;
SELECT * FROM orders WHERE user_id = 2;
-- ... 10번 반복

-- ✅ 해결: JOIN 사용
SELECT
    u.id,
    u.name,
    json_agg(
        json_build_object(
            'id', o.id,
            'total', o.total_amount,
            'status', o.status
        )
    ) as orders
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.name
LIMIT 10;

-- ✅ 해결: LATERAL JOIN (복잡한 서브쿼리)
SELECT
    u.id,
    u.name,
    recent_orders.*
FROM users u
LEFT JOIN LATERAL (
    SELECT
        json_agg(
            json_build_object('id', id, 'total', total_amount)
            ORDER BY created_at DESC
        ) as orders
    FROM orders
    WHERE user_id = u.id
    LIMIT 5
) recent_orders ON TRUE
LIMIT 10;
```

### CTE 최적화

```sql
-- ❌ 비효율적 CTE (여러 번 실행)
WITH user_stats AS (
    SELECT user_id, COUNT(*) as count
    FROM orders
    GROUP BY user_id
)
SELECT * FROM user_stats WHERE count > 10
UNION ALL
SELECT * FROM user_stats WHERE count <= 10;

-- ✅ 효율적: MATERIALIZED CTE
WITH user_stats AS MATERIALIZED (
    SELECT user_id, COUNT(*) as count
    FROM orders
    GROUP BY user_id
)
SELECT * FROM user_stats WHERE count > 10
UNION ALL
SELECT * FROM user_stats WHERE count <= 10;

-- ✅ 재귀 CTE 최적화
WITH RECURSIVE category_tree AS (
    -- 최상위
    SELECT id, name, parent_id, 1 as level
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    -- 하위 (깊이 제한)
    SELECT c.id, c.name, c.parent_id, ct.level + 1
    FROM categories c
    JOIN category_tree ct ON c.parent_id = ct.id
    WHERE ct.level < 5  -- 깊이 제한으로 무한 루프 방지
)
SELECT * FROM category_tree;
```

## 📈 통계 및 분석

### 테이블 통계 업데이트

```sql
-- 통계 수집 (쿼리 플래너가 사용)
ANALYZE users;

-- 모든 테이블
ANALYZE;

-- VACUUM과 함께 (죽은 튜플 제거 + 통계)
VACUUM ANALYZE users;

-- 통계 확인
SELECT
    schemaname,
    tablename,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables;
```

### 느린 쿼리 찾기

```sql
-- pg_stat_statements 확장 (설치 필요)
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 느린 쿼리 TOP 10
SELECT
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- 가장 많이 호출되는 쿼리
SELECT
    query,
    calls,
    total_exec_time / 1000 as total_sec
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT 10;
```

### 인덱스 효율성 분석

```sql
-- 사용되지 않는 인덱스
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND indexrelid IS NOT NULL
ORDER BY pg_relation_size(indexrelid) DESC;

-- 인덱스 히트율
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    CASE
        WHEN idx_tup_read = 0 THEN 0
        ELSE ROUND(100.0 * idx_tup_fetch / idx_tup_read, 2)
    END as hit_ratio
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

## 🛠️ 실습 과제

파일: [exercises.sql](./exercises.sql)

### 과제 1: EXPLAIN 분석
주어진 쿼리의 실행 계획을 분석하고 최적화하세요.

### 과제 2: 인덱스 최적화
적절한 인덱스를 만들어 쿼리 성능을 개선하세요.

### 과제 3: N+1 문제 해결
N+1 쿼리 패턴을 찾아 최적화하세요.

## ✅ 체크리스트

- [ ] EXPLAIN ANALYZE 결과 해석 가능
- [ ] 복합 인덱스 순서 이해
- [ ] 부분 인덱스 활용
- [ ] 전문 검색 인덱스 생성
- [ ] N+1 문제 식별 및 해결
- [ ] 키셋 페이지네이션 구현
- [ ] CTE 최적화
- [ ] 느린 쿼리 찾아 개선 (10개 이상)

## 📚 다음 단계

- [02. 백업/복구](../02-backup-recovery/)
- PostgreSQL Performance: https://www.postgresql.org/docs/current/performance-tips.html

---

**완료 예상 시간**: 15-20시간
**난이도**: ⭐⭐⭐⭐☆
