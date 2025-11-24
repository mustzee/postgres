-- ====================================
-- Phase 1 - 데이터 모델링 실습
-- ====================================

\c learning_db

-- ====================================
-- 과제 1: 블로그 시스템 설계
-- ====================================

-- 요구사항:
-- 1. 사용자(users): 이메일, 비밀번호, 이름, 프로필
-- 2. 게시글(posts): 제목, 내용, 작성자, 상태(draft/published)
-- 3. 댓글(comments): 내용, 작성자, 게시글, 부모 댓글(대댓글 지원)
-- 4. 태그(tags): 이름
-- 5. 게시글-태그 관계(post_tags): N:M 관계

-- 사용자 테이블
CREATE TABLE blog_users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    username VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100),
    bio TEXT,
    avatar_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 게시글 테이블
CREATE TABLE blog_posts (
    id SERIAL PRIMARY KEY,
    author_id INTEGER NOT NULL REFERENCES blog_users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(200) NOT NULL UNIQUE,
    content TEXT,
    excerpt TEXT,
    status VARCHAR(20) DEFAULT 'draft',
    view_count INTEGER DEFAULT 0,
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT check_status CHECK (status IN ('draft', 'published', 'archived'))
);

-- 댓글 테이블 (자기 참조로 대댓글 지원)
CREATE TABLE blog_comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES blog_posts(id) ON DELETE CASCADE,
    author_id INTEGER NOT NULL REFERENCES blog_users(id) ON DELETE CASCADE,
    parent_id INTEGER REFERENCES blog_comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 태그 테이블
CREATE TABLE blog_tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    slug VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 게시글-태그 중간 테이블 (N:M 관계)
CREATE TABLE blog_post_tags (
    post_id INTEGER REFERENCES blog_posts(id) ON DELETE CASCADE,
    tag_id INTEGER REFERENCES blog_tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (post_id, tag_id)
);

-- ====================================
-- 인덱스 생성
-- ====================================

-- 게시글 인덱스
CREATE INDEX idx_blog_posts_author ON blog_posts(author_id);
CREATE INDEX idx_blog_posts_status ON blog_posts(status);
CREATE INDEX idx_blog_posts_published ON blog_posts(published_at) WHERE status = 'published';

-- 댓글 인덱스
CREATE INDEX idx_blog_comments_post ON blog_comments(post_id);
CREATE INDEX idx_blog_comments_author ON blog_comments(author_id);
CREATE INDEX idx_blog_comments_parent ON blog_comments(parent_id);

-- 태그 인덱스
CREATE INDEX idx_blog_tags_slug ON blog_tags(slug);

-- 전문 검색 인덱스 (제목 + 내용)
CREATE INDEX idx_blog_posts_search ON blog_posts
USING GIN (to_tsvector('english', title || ' ' || COALESCE(content, '')));

-- ====================================
-- 샘플 데이터 삽입
-- ====================================

-- 사용자
INSERT INTO blog_users (email, password_hash, username, display_name) VALUES
    ('alice@blog.com', 'hash1', 'alice', 'Alice Writer'),
    ('bob@blog.com', 'hash2', 'bob', 'Bob Blogger'),
    ('charlie@blog.com', 'hash3', 'charlie', 'Charlie Commenter');

-- 태그
INSERT INTO blog_tags (name, slug) VALUES
    ('PostgreSQL', 'postgresql'),
    ('Web Development', 'web-development'),
    ('Tutorial', 'tutorial'),
    ('Performance', 'performance'),
    ('Cloud', 'cloud');

-- 게시글
INSERT INTO blog_posts (author_id, title, slug, content, status, published_at) VALUES
    (1, 'Getting Started with PostgreSQL', 'getting-started-postgresql',
     'PostgreSQL is a powerful database...', 'published', NOW() - INTERVAL '7 days'),
    (1, 'Advanced SQL Techniques', 'advanced-sql-techniques',
     'Learn about CTEs, window functions...', 'published', NOW() - INTERVAL '3 days'),
    (2, 'Building APIs with Node.js', 'building-apis-nodejs',
     'Step by step guide to building REST APIs...', 'published', NOW() - INTERVAL '1 day'),
    (2, 'Draft: Upcoming Features', 'upcoming-features',
     'This is a draft post...', 'draft', NULL);

-- 게시글-태그 연결
INSERT INTO blog_post_tags (post_id, tag_id) VALUES
    (1, 1), (1, 3),  -- PostgreSQL + Tutorial
    (2, 1), (2, 4),  -- PostgreSQL + Performance
    (3, 2), (3, 3);  -- Web Dev + Tutorial

-- 댓글
INSERT INTO blog_comments (post_id, author_id, content) VALUES
    (1, 2, 'Great tutorial! Very helpful.'),
    (1, 3, 'Thanks for sharing!');

-- 대댓글
INSERT INTO blog_comments (post_id, author_id, parent_id, content) VALUES
    (1, 1, 1, 'Thank you! Glad it helped.');

-- ====================================
-- 실용 쿼리 예제
-- ====================================

-- 1. 게시글 목록 (태그 포함)
SELECT
    p.id,
    p.title,
    u.display_name as author,
    array_agg(t.name) as tags,
    p.view_count,
    p.published_at
FROM blog_posts p
JOIN blog_users u ON p.author_id = u.id
LEFT JOIN blog_post_tags pt ON p.id = pt.post_id
LEFT JOIN blog_tags t ON pt.tag_id = t.id
WHERE p.status = 'published'
GROUP BY p.id, u.display_name
ORDER BY p.published_at DESC;

-- 2. 게시글 상세 (댓글 개수 포함)
SELECT
    p.*,
    u.display_name as author,
    u.avatar_url as author_avatar,
    COUNT(c.id) as comment_count
FROM blog_posts p
JOIN blog_users u ON p.author_id = u.id
LEFT JOIN blog_comments c ON p.id = c.post_id AND c.is_deleted = FALSE
WHERE p.id = 1
GROUP BY p.id, u.display_name, u.avatar_url;

-- 3. 댓글 계층 구조 (재귀 CTE)
WITH RECURSIVE comment_tree AS (
    -- 최상위 댓글
    SELECT
        c.id,
        c.content,
        c.author_id,
        u.display_name as author,
        c.parent_id,
        1 as level,
        c.created_at,
        ARRAY[c.id] as path
    FROM blog_comments c
    JOIN blog_users u ON c.author_id = u.id
    WHERE c.post_id = 1 AND c.parent_id IS NULL AND c.is_deleted = FALSE

    UNION ALL

    -- 대댓글
    SELECT
        c.id,
        c.content,
        c.author_id,
        u.display_name,
        c.parent_id,
        ct.level + 1,
        c.created_at,
        ct.path || c.id
    FROM blog_comments c
    JOIN blog_users u ON c.author_id = u.id
    JOIN comment_tree ct ON c.parent_id = ct.id
    WHERE c.is_deleted = FALSE
)
SELECT
    REPEAT('  ', level - 1) || author as threaded_author,
    content,
    level,
    created_at
FROM comment_tree
ORDER BY path;

-- 4. 인기 태그 (게시글 수 기준)
SELECT
    t.name,
    COUNT(pt.post_id) as post_count
FROM blog_tags t
LEFT JOIN blog_post_tags pt ON t.id = pt.tag_id
LEFT JOIN blog_posts p ON pt.post_id = p.id AND p.status = 'published'
GROUP BY t.id, t.name
HAVING COUNT(pt.post_id) > 0
ORDER BY post_count DESC;

-- 5. 작성자별 통계
SELECT
    u.display_name,
    COUNT(DISTINCT p.id) as post_count,
    COUNT(DISTINCT c.id) as comment_count,
    MAX(p.published_at) as last_post_date
FROM blog_users u
LEFT JOIN blog_posts p ON u.id = p.author_id AND p.status = 'published'
LEFT JOIN blog_comments c ON u.id = c.author_id AND c.is_deleted = FALSE
GROUP BY u.id, u.display_name
ORDER BY post_count DESC;

-- 6. 전문 검색
SELECT
    title,
    excerpt,
    ts_rank(to_tsvector('english', title || ' ' || content), query) as rank
FROM blog_posts,
     to_tsquery('english', 'postgresql & performance') as query
WHERE to_tsvector('english', title || ' ' || content) @@ query
ORDER BY rank DESC;

-- ====================================
-- 과제 2: 정규화 실습
-- ====================================

-- 비정규화된 주문 테이블 (1NF 위반)
CREATE TABLE orders_denormalized (
    id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    customer_email VARCHAR(100),
    customer_phone VARCHAR(20),
    customer_address TEXT,
    product_names TEXT,  -- '상품A, 상품B, 상품C' (1NF 위반)
    product_prices TEXT, -- '10000, 20000, 15000' (1NF 위반)
    total_amount DECIMAL(10,2),
    order_date TIMESTAMP
);

-- TODO: 위 테이블을 3NF까지 정규화하세요
-- 힌트: customers, products, orders, order_items 테이블로 분리

-- ====================================
-- 과제 3: 성능 최적화
-- ====================================

-- 아래 쿼리의 성능을 분석하고 개선하세요

-- 느린 쿼리
EXPLAIN ANALYZE
SELECT
    p.title,
    u.display_name,
    COUNT(c.id) as comment_count
FROM blog_posts p
JOIN blog_users u ON p.author_id = u.id
LEFT JOIN blog_comments c ON p.id = c.post_id
WHERE p.status = 'published'
  AND p.published_at > NOW() - INTERVAL '30 days'
GROUP BY p.id, p.title, u.display_name
ORDER BY comment_count DESC
LIMIT 10;

-- TODO:
-- 1. EXPLAIN 결과를 분석하세요
-- 2. 필요한 인덱스를 생성하세요
-- 3. 쿼리를 최적화하세요
-- 4. 개선 전후를 비교하세요

-- ====================================
-- 보너스: 뷰와 함수 생성
-- ====================================

-- 게시글 목록 뷰
CREATE OR REPLACE VIEW blog_post_list AS
SELECT
    p.id,
    p.title,
    p.slug,
    p.excerpt,
    p.view_count,
    p.published_at,
    u.display_name as author,
    u.avatar_url as author_avatar,
    COUNT(DISTINCT c.id) as comment_count,
    array_agg(DISTINCT t.name) FILTER (WHERE t.name IS NOT NULL) as tags
FROM blog_posts p
JOIN blog_users u ON p.author_id = u.id
LEFT JOIN blog_comments c ON p.id = c.post_id AND c.is_deleted = FALSE
LEFT JOIN blog_post_tags pt ON p.id = pt.post_id
LEFT JOIN blog_tags t ON pt.tag_id = t.id
WHERE p.status = 'published'
GROUP BY p.id, u.display_name, u.avatar_url;

-- 조회수 증가 함수
CREATE OR REPLACE FUNCTION increment_view_count(post_id_param INTEGER)
RETURNS VOID AS $$
BEGIN
    UPDATE blog_posts
    SET view_count = view_count + 1
    WHERE id = post_id_param;
END;
$$ LANGUAGE plpgsql;

-- 사용 예:
-- SELECT increment_view_count(1);

-- ====================================
-- 테이블 크기 확인
-- ====================================

SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public' AND tablename LIKE 'blog_%'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

\echo '✅ Blog system created successfully!'
\echo '📊 Try: SELECT * FROM blog_post_list;'
