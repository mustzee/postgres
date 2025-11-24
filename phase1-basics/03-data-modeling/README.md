# 03. 데이터 모델링

## 🎯 학습 목표

- 정규화 (Normalization) 이해 및 적용
- ERD (Entity-Relationship Diagram) 설계
- 인덱스 기초 및 활용
- 관계형 데이터베이스 설계 원칙

## 📚 데이터 모델링이란?

데이터 모델링은 현실 세계의 데이터를 데이터베이스에 표현하는 과정입니다.

### 3단계 모델링

1. **개념적 모델링** - 업무 분석 및 ERD 작성
2. **논리적 모델링** - 정규화 및 테이블 설계
3. **물리적 모델링** - 인덱스, 파티션 등 성능 최적화

## 🔧 정규화 (Normalization)

### 정규화가 필요한 이유

- **데이터 중복 제거** - 저장 공간 절약
- **이상 현상 방지** - 삽입/수정/삭제 이상
- **데이터 무결성 보장** - 일관성 유지

### 제1정규형 (1NF)

**규칙**: 모든 속성은 원자값(Atomic Value)을 가져야 함

❌ **비정규형**
```sql
CREATE TABLE students_bad (
    id INTEGER PRIMARY KEY,
    name VARCHAR(100),
    courses VARCHAR(500)  -- '수학, 영어, 과학' (여러 값 저장)
);
```

✅ **제1정규형**
```sql
CREATE TABLE students (
    id INTEGER PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE courses (
    id INTEGER PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE student_courses (
    student_id INTEGER REFERENCES students(id),
    course_id INTEGER REFERENCES courses(id),
    PRIMARY KEY (student_id, course_id)
);
```

### 제2정규형 (2NF)

**규칙**: 제1정규형 + 부분 함수 종속 제거

❌ **1NF (부분 함수 종속 존재)**
```sql
CREATE TABLE order_items_bad (
    order_id INTEGER,
    product_id INTEGER,
    product_name VARCHAR(100),    -- product_id에만 종속
    product_price DECIMAL(10,2),  -- product_id에만 종속
    quantity INTEGER,
    PRIMARY KEY (order_id, product_id)
);
-- 문제: product_name, price는 order_id와 무관하게 product_id에만 종속됨
```

✅ **제2정규형**
```sql
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(10,2)
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE order_items (
    order_id INTEGER REFERENCES orders(id),
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER,
    PRIMARY KEY (order_id, product_id)
);
```

### 제3정규형 (3NF)

**규칙**: 제2정규형 + 이행 함수 종속 제거

❌ **2NF (이행 함수 종속 존재)**
```sql
CREATE TABLE employees_bad (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    department_id INTEGER,
    department_name VARCHAR(100),  -- department_id를 통한 이행 종속
    department_location VARCHAR(100)  -- department_id를 통한 이행 종속
);
-- 문제: department_name, location은 employee_id -> department_id -> department_name
```

✅ **제3정규형**
```sql
CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    location VARCHAR(100)
);

CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    department_id INTEGER REFERENCES departments(id)
);
```

### BCNF (Boyce-Codd Normal Form)

**규칙**: 제3정규형 + 모든 결정자는 후보키

```sql
-- 예: 강의실, 시간대, 교수 관계
CREATE TABLE schedules (
    room_id INTEGER,
    time_slot VARCHAR(20),
    professor_id INTEGER,
    course_id INTEGER,
    PRIMARY KEY (room_id, time_slot),
    UNIQUE (professor_id, time_slot)
);
-- BCNF: professor_id + time_slot도 후보키
```

### 역정규화 (Denormalization)

성능을 위해 의도적으로 중복을 허용하는 경우:

```sql
-- 정규화된 형태
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER,
    order_date TIMESTAMP
);

CREATE TABLE order_items (
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    price DECIMAL(10,2)
);

-- 역정규화: 성능을 위해 total 컬럼 추가
ALTER TABLE orders ADD COLUMN total_amount DECIMAL(12,2);

-- 트리거로 자동 계산
CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE orders
    SET total_amount = (
        SELECT SUM(quantity * price)
        FROM order_items
        WHERE order_id = NEW.order_id
    )
    WHERE id = NEW.order_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER order_item_changed
AFTER INSERT OR UPDATE OR DELETE ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_order_total();
```

## 🔗 관계 (Relationships)

### 1:1 (One-to-One) 관계

```sql
-- 예: 직원 - 주차 공간
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE parking_spaces (
    id SERIAL PRIMARY KEY,
    location VARCHAR(50),
    employee_id INTEGER UNIQUE REFERENCES employees(id)
    -- UNIQUE 제약으로 1:1 관계 보장
);
```

### 1:N (One-to-Many) 관계

```sql
-- 예: 부서 - 직원
CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    department_id INTEGER REFERENCES departments(id)
    -- 외래키로 N:1 관계 표현
);
```

### N:M (Many-to-Many) 관계

```sql
-- 예: 학생 - 수업
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);

-- 중간 테이블 (Junction Table)
CREATE TABLE enrollments (
    student_id INTEGER REFERENCES students(id),
    course_id INTEGER REFERENCES courses(id),
    enrolled_date DATE DEFAULT CURRENT_DATE,
    grade VARCHAR(2),
    PRIMARY KEY (student_id, course_id)
);
```

### 자기 참조 관계 (Self-Referencing)

```sql
-- 예: 직원 - 매니저
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    manager_id INTEGER REFERENCES employees(id)
);

-- 조직도 조회
WITH RECURSIVE org_chart AS (
    -- 최상위 (CEO)
    SELECT id, name, manager_id, 1 as level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- 하위 직원
    SELECT e.id, e.name, e.manager_id, oc.level + 1
    FROM employees e
    JOIN org_chart oc ON e.manager_id = oc.id
)
SELECT * FROM org_chart ORDER BY level, id;
```

## 🎨 ERD 설계 예제

### 예제: 온라인 쇼핑몰

```sql
-- 사용자
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 카테고리
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    parent_id INTEGER REFERENCES categories(id),
    slug VARCHAR(100) UNIQUE
);

-- 상품
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES categories(id),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    stock INTEGER DEFAULT 0 CHECK (stock >= 0),
    image_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 장바구니
CREATE TABLE cart_items (
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, product_id)
);

-- 주문
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'pending',
    total_amount DECIMAL(12,2) NOT NULL,
    shipping_address TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT check_order_status
        CHECK (status IN ('pending', 'paid', 'shipped', 'delivered', 'cancelled'))
);

-- 주문 상세
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,  -- 주문 당시 가격 저장

    CONSTRAINT check_quantity CHECK (quantity > 0),
    CONSTRAINT check_price CHECK (price >= 0)
);

-- 리뷰
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (product_id, user_id)  -- 사용자당 상품 1개의 리뷰만
);

-- 인덱스 생성
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_active ON products(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_reviews_product ON reviews(product_id);
```

## 📊 인덱스 기초

### 인덱스란?

데이터 검색 속도를 높이기 위한 자료구조 (책의 색인과 유사)

### 인덱스 생성

```sql
-- 단일 컬럼 인덱스
CREATE INDEX idx_users_email ON users(email);

-- 복합 인덱스
CREATE INDEX idx_orders_user_date ON orders(user_id, created_at);

-- 유니크 인덱스
CREATE UNIQUE INDEX idx_unique_email ON users(email);

-- 부분 인덱스
CREATE INDEX idx_active_products
ON products(name)
WHERE is_active = TRUE;

-- 표현식 인덱스
CREATE INDEX idx_lower_email ON users(LOWER(email));

-- 전문 검색 인덱스
CREATE INDEX idx_product_search
ON products
USING GIN (to_tsvector('english', name || ' ' || description));
```

### 인덱스 확인

```sql
-- 테이블의 인덱스 목록
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'users';

-- 인덱스 사용 통계
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- 사용되지 않는 인덱스 찾기
SELECT
    schemaname,
    tablename,
    indexname
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND indexname NOT LIKE '%_pkey';
```

### 인덱스 사용 확인 (EXPLAIN)

```sql
-- EXPLAIN으로 쿼리 계획 확인
EXPLAIN SELECT * FROM products WHERE category_id = 1;

-- EXPLAIN ANALYZE로 실제 실행 분석
EXPLAIN ANALYZE
SELECT * FROM products
WHERE is_active = TRUE
  AND price BETWEEN 10000 AND 50000;
```

### 인덱스 사용 가이드

✅ **인덱스를 만들어야 하는 경우**
- WHERE 절에 자주 사용되는 컬럼
- JOIN에 사용되는 컬럼
- ORDER BY에 사용되는 컬럼
- UNIQUE 제약이 필요한 컬럼

❌ **인덱스를 피해야 하는 경우**
- 테이블이 작은 경우 (< 1000 rows)
- 자주 수정되는 컬럼
- 카디널리티가 낮은 컬럼 (성별, boolean 등)
- 대부분의 값이 NULL인 컬럼

## 📝 실습 과제

파일: [exercises.sql](./exercises.sql)

### 과제 1: 블로그 시스템 설계

다음 요구사항을 만족하는 블로그 시스템을 설계하세요:
- 사용자, 게시글, 댓글, 태그
- 게시글-태그 N:M 관계
- 댓글의 대댓글 지원
- 정규화 3NF까지 적용

### 과제 2: 정규화 실습

비정규화된 테이블을 3NF까지 정규화하세요.

### 과제 3: 인덱스 최적화

주어진 쿼리를 분석하고 적절한 인덱스를 생성하세요.

## ✅ 체크리스트

- [ ] 1NF, 2NF, 3NF 이해 및 설명 가능
- [ ] ERD 직접 그리기
- [ ] 1:1, 1:N, N:M 관계 구현
- [ ] 자기 참조 관계 활용
- [ ] 인덱스 5개 이상 생성
- [ ] EXPLAIN ANALYZE 사용
- [ ] 복합 인덱스와 부분 인덱스 이해
- [ ] 실제 프로젝트 ERD 설계 (Epicodix 등)

## 📚 추가 학습 자료

- [Database Normalization](https://www.postgresql.org/docs/current/tutorial-start.html)
- [PostgreSQL Indexes](https://www.postgresql.org/docs/current/indexes.html)
- [ERD 도구] dbdiagram.io, draw.io

---

**완료 예상 시간**: 10-12시간
**난이도**: ⭐⭐⭐☆☆
