# 01. NoSQL 하이브리드 아키텍처

## 🎯 학습 목표

- PostgreSQL의 JSON/JSONB 활용
- PostgreSQL + Redis 연동
- PostgreSQL + MongoDB 하이브리드
- 폴리글랏 퍼시스턴스 (Polyglot Persistence)

## 📦 PostgreSQL JSON/JSONB

### JSON vs JSONB

```sql
-- JSON: 텍스트 저장, 입력 속도 빠름
CREATE TABLE events_json (
    id SERIAL PRIMARY KEY,
    data JSON
);

-- JSONB: 바이너리 저장, 쿼리 속도 빠름, 인덱싱 가능 (권장)
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### JSONB 기본 조작

```sql
-- 데이터 삽입
INSERT INTO events (data) VALUES
('{"user_id": 1, "action": "login", "ip": "192.168.1.1", "metadata": {"device": "mobile"}}'),
('{"user_id": 2, "action": "purchase", "amount": 99.99, "items": ["item1", "item2"]}'),
('{"user_id": 1, "action": "logout", "session_duration": 3600}');

-- JSON 필드 접근 (-> 연산자)
SELECT data->'user_id' FROM events;           -- JSON 타입 반환
SELECT data->>'user_id' FROM events;          -- 텍스트 반환
SELECT data->'metadata'->'device' FROM events;
SELECT data->'metadata'->>'device' FROM events;

-- 배열 접근
SELECT data->'items'->0 FROM events;          -- 첫 번째 항목
SELECT data->>'items'->1 FROM events;         -- 두 번째 항목

-- 경로 접근 (#> 연산자)
SELECT data #> '{metadata,device}' FROM events;
SELECT data #>> '{metadata,device}' FROM events;  -- 텍스트
```

### JSONB 쿼리

```sql
-- 특정 키 존재 확인
SELECT * FROM events WHERE data ? 'amount';

-- 여러 키 존재 확인
SELECT * FROM events WHERE data ?& array['user_id', 'action'];

-- 값으로 검색
SELECT * FROM events WHERE data->>'action' = 'login';
SELECT * FROM events WHERE (data->>'user_id')::int = 1;
SELECT * FROM events WHERE (data->>'amount')::numeric > 50;

-- 포함 관계 (@> 연산자)
SELECT * FROM events
WHERE data @> '{"action": "login"}';

SELECT * FROM events
WHERE data @> '{"metadata": {"device": "mobile"}}';

-- 배열 연산
SELECT * FROM events
WHERE data->'items' @> '["item1"]';
```

### JSONB 수정

```sql
-- 필드 추가/업데이트
UPDATE events
SET data = data || '{"verified": true}'
WHERE data->>'action' = 'login';

-- 중첩 필드 업데이트
UPDATE events
SET data = jsonb_set(data, '{metadata,device}', '"desktop"')
WHERE id = 1;

-- 필드 삭제
UPDATE events
SET data = data - 'session_duration'
WHERE id = 3;

-- 중첩 필드 삭제
UPDATE events
SET data = data #- '{metadata,device}'
WHERE id = 1;
```

### JSONB 인덱싱

```sql
-- GIN 인덱스 (포함 관계 검색에 최적)
CREATE INDEX idx_events_data ON events USING GIN (data);

-- 특정 경로 인덱싱
CREATE INDEX idx_events_user_id ON events ((data->>'user_id'));
CREATE INDEX idx_events_action ON events ((data->>'action'));

-- 표현식 인덱스
CREATE INDEX idx_events_amount
ON events (((data->>'amount')::numeric))
WHERE data ? 'amount';

-- 부분 인덱스
CREATE INDEX idx_login_events
ON events USING GIN (data)
WHERE data->>'action' = 'login';
```

### JSONB 함수

```sql
-- jsonb_array_elements: 배열 요소 전개
SELECT
    id,
    jsonb_array_elements(data->'items') as item
FROM events
WHERE data ? 'items';

-- jsonb_each: 키-값 쌍 전개
SELECT
    id,
    (jsonb_each(data)).key,
    (jsonb_each(data)).value
FROM events;

-- jsonb_object_keys: 키 목록
SELECT DISTINCT jsonb_object_keys(data) FROM events;

-- jsonb_build_object: JSON 객체 생성
SELECT jsonb_build_object(
    'user_id', data->>'user_id',
    'action', data->>'action',
    'timestamp', created_at
) FROM events;

-- jsonb_agg: JSON 배열로 집계
SELECT
    data->>'user_id' as user_id,
    jsonb_agg(data->>'action') as actions
FROM events
GROUP BY data->>'user_id';
```

### 실용 예제: 사용자 설정 저장

```sql
CREATE TABLE user_preferences (
    user_id INTEGER PRIMARY KEY,
    preferences JSONB DEFAULT '{}',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 인덱스 생성
CREATE INDEX idx_user_preferences ON user_preferences USING GIN (preferences);

-- 설정 저장
INSERT INTO user_preferences (user_id, preferences) VALUES
(1, '{"theme": "dark", "language": "ko", "notifications": {"email": true, "push": false}}'),
(2, '{"theme": "light", "language": "en", "notifications": {"email": false, "push": true}}');

-- 설정 조회
SELECT preferences->>'theme' as theme FROM user_preferences WHERE user_id = 1;

-- 설정 업데이트
UPDATE user_preferences
SET
    preferences = jsonb_set(preferences, '{notifications,email}', 'false'),
    updated_at = CURRENT_TIMESTAMP
WHERE user_id = 1;

-- 특정 설정 값으로 사용자 검색
SELECT user_id FROM user_preferences
WHERE preferences @> '{"theme": "dark"}';

SELECT user_id FROM user_preferences
WHERE preferences #>> '{notifications,email}' = 'true';
```

## 🔴 PostgreSQL + Redis 연동

### Redis 사용 시나리오

- **세션 관리**: 빠른 읽기/쓰기
- **캐시**: 자주 조회되는 데이터
- **실시간 데이터**: 조회수, 좋아요
- **큐/Pub-Sub**: 메시지 브로커

### Docker Compose 설정

```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
```

### 하이브리드 패턴: Cache-Aside

```python
import psycopg2
import redis
import json

# 연결
pg_conn = psycopg2.connect("dbname=mydb user=postgres")
redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)

def get_user(user_id):
    # 1. Redis 캐시 확인
    cache_key = f"user:{user_id}"
    cached = redis_client.get(cache_key)

    if cached:
        print("Cache hit!")
        return json.loads(cached)

    # 2. PostgreSQL에서 조회
    print("Cache miss - querying database")
    with pg_conn.cursor() as cur:
        cur.execute("SELECT * FROM users WHERE id = %s", (user_id,))
        user = cur.fetchone()

    if user:
        # 3. Redis에 캐시 (TTL: 1시간)
        redis_client.setex(cache_key, 3600, json.dumps(user))

    return user

def update_user(user_id, data):
    # 1. PostgreSQL 업데이트
    with pg_conn.cursor() as cur:
        cur.execute(
            "UPDATE users SET name = %s WHERE id = %s",
            (data['name'], user_id)
        )
        pg_conn.commit()

    # 2. Redis 캐시 무효화
    cache_key = f"user:{user_id}"
    redis_client.delete(cache_key)
```

### 패턴: Write-Through Cache

```python
def create_post(user_id, title, content):
    # 1. PostgreSQL에 저장
    with pg_conn.cursor() as cur:
        cur.execute(
            "INSERT INTO posts (user_id, title, content) VALUES (%s, %s, %s) RETURNING id",
            (user_id, title, content)
        )
        post_id = cur.fetchone()[0]
        pg_conn.commit()

    # 2. Redis에 즉시 캐시
    cache_key = f"post:{post_id}"
    post_data = {
        'id': post_id,
        'user_id': user_id,
        'title': title,
        'content': content
    }
    redis_client.setex(cache_key, 3600, json.dumps(post_data))

    # 3. 사용자의 게시글 목록에 추가
    user_posts_key = f"user:{user_id}:posts"
    redis_client.zadd(user_posts_key, {post_id: time.time()})

    return post_id
```

### 패턴: 조회수 카운터

```python
# Redis로 실시간 조회수 관리
def increment_view_count(post_id):
    key = f"post:{post_id}:views"
    redis_client.incr(key)

def get_view_count(post_id):
    key = f"post:{post_id}:views"
    return int(redis_client.get(key) or 0)

# 주기적으로 PostgreSQL에 동기화 (예: 5분마다)
def sync_view_counts_to_postgres():
    pattern = "post:*:views"
    for key in redis_client.scan_iter(pattern):
        post_id = key.split(':')[1]
        views = redis_client.get(key)

        with pg_conn.cursor() as cur:
            cur.execute(
                "UPDATE posts SET view_count = view_count + %s WHERE id = %s",
                (int(views), post_id)
            )

        # Redis 카운터 초기화
        redis_client.delete(key)

    pg_conn.commit()
```

### 패턴: Leaderboard (순위표)

```sql
-- PostgreSQL: 사용자 점수 저장
CREATE TABLE user_scores (
    user_id INTEGER PRIMARY KEY,
    score INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

```python
# Redis Sorted Set으로 실시간 순위
def update_score(user_id, score):
    # 1. PostgreSQL 업데이트
    with pg_conn.cursor() as cur:
        cur.execute(
            "UPDATE user_scores SET score = %s, updated_at = NOW() WHERE user_id = %s",
            (score, user_id)
        )
        pg_conn.commit()

    # 2. Redis 순위표 업데이트
    redis_client.zadd("leaderboard", {user_id: score})

def get_top_users(n=10):
    # Redis에서 빠르게 조회
    return redis_client.zrevrange("leaderboard", 0, n-1, withscores=True)

def get_user_rank(user_id):
    # Redis에서 순위 조회 (O(log N))
    rank = redis_client.zrevrank("leaderboard", user_id)
    return rank + 1 if rank is not None else None
```

## 🍃 PostgreSQL + MongoDB 하이브리드

### 언제 MongoDB를 추가할까?

- ✅ 스키마가 자주 변경되는 데이터
- ✅ 로그, 이벤트 등 비정형 데이터
- ✅ 계층적 데이터 (중첩 문서)
- ❌ 트랜잭션이 중요한 데이터 → PostgreSQL

### 예시: E-commerce 하이브리드

```python
# PostgreSQL: 주문 정보 (트랜잭션 중요)
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    total_amount DECIMAL(10,2),
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

# MongoDB: 제품 카탈로그 (스키마 유연성)
# products collection
{
    "_id": ObjectId("..."),
    "name": "Laptop",
    "category": "Electronics",
    "price": 999.99,
    "specs": {
        "cpu": "Intel i7",
        "ram": "16GB",
        "storage": "512GB SSD"
    },
    "reviews": [
        {"user_id": 1, "rating": 5, "comment": "Great!"},
        {"user_id": 2, "rating": 4, "comment": "Good value"}
    ]
}
```

```python
from pymongo import MongoClient
import psycopg2

mongo_client = MongoClient('mongodb://localhost:27017/')
mongo_db = mongo_client['ecommerce']

pg_conn = psycopg2.connect("dbname=ecommerce user=postgres")

def create_order(user_id, product_ids):
    # 1. MongoDB에서 제품 정보 조회
    products = mongo_db.products.find({"_id": {"$in": product_ids}})
    total = sum(p['price'] for p in products)

    # 2. PostgreSQL에 주문 생성 (트랜잭션)
    with pg_conn.cursor() as cur:
        cur.execute(
            "INSERT INTO orders (user_id, total_amount, status) VALUES (%s, %s, 'pending') RETURNING id",
            (user_id, total)
        )
        order_id = cur.fetchone()[0]
        pg_conn.commit()

    return order_id
```

## 🏗️ 폴리글랏 퍼시스턴스 아키텍처

### 데이터 저장소 선택 가이드

| 데이터 유형 | 권장 저장소 | 이유 |
|------------|----------|------|
| 사용자, 주문, 결제 | PostgreSQL | ACID 트랜잭션 필요 |
| 세션, 캐시 | Redis | 빠른 읽기/쓰기 |
| 제품 카탈로그 | PostgreSQL JSONB 또는 MongoDB | 스키마 유연성 |
| 로그, 이벤트 | Elasticsearch | 전문 검색 |
| 파일, 이미지 | S3, GCS | 객체 스토리지 |
| 시계열 데이터 | TimescaleDB | 시계열 최적화 |

### 예시: 종합 아키텍처

```
[클라이언트]
    |
    v
[API 서버]
    |
    +-- PostgreSQL (주문, 사용자, 결제)
    +-- Redis (세션, 캐시, 실시간 데이터)
    +-- MongoDB (제품, 로그)
    +-- S3 (이미지, 파일)
    +-- Elasticsearch (검색)
```

## 🛠️ 실습 과제

### 과제 1: JSONB 활용
사용자 활동 로그 시스템을 JSONB로 구현하세요.

### 과제 2: Redis 캐싱
Cache-Aside 패턴으로 조회 성능을 개선하세요.

### 과제 3: 하이브리드 설계
실제 프로젝트(Epicodix 등)에 폴리글랏 퍼시스턴스를 적용하세요.

## ✅ 체크리스트

- [ ] JSONB 기본 CRUD 작성
- [ ] GIN 인덱스 활용
- [ ] Redis와 PostgreSQL 연동
- [ ] Cache-Aside 패턴 구현
- [ ] Write-Through 패턴 구현
- [ ] Leaderboard 시스템 구축
- [ ] MongoDB와 PostgreSQL 하이브리드 설계
- [ ] 폴리글랏 아키텍처 설계

---

**완료 예상 시간**: 15-20시간
**난이도**: ⭐⭐⭐⭐⭐
