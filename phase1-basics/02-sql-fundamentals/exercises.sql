-- ====================================
-- Phase 1 - SQL 기초 실습 문제
-- ====================================

-- 실습 준비
\c learning_db

-- ====================================
-- 과제 1: 테이블 생성
-- ====================================

-- 1-1. departments (부서) 테이블 생성
CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    location VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 1-2. employees (직원) 테이블 생성
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    employee_number VARCHAR(10) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    hire_date DATE NOT NULL,
    salary DECIMAL(10, 2) CHECK (salary > 0),
    department_id INTEGER,
    manager_id INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_department
        FOREIGN KEY (department_id)
        REFERENCES departments(id)
        ON DELETE SET NULL,

    CONSTRAINT fk_manager
        FOREIGN KEY (manager_id)
        REFERENCES employees(id)
        ON DELETE SET NULL
);

-- 1-3. projects (프로젝트) 테이블 생성
CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    budget DECIMAL(12, 2),
    status VARCHAR(20) DEFAULT 'planning',
    department_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_project_department
        FOREIGN KEY (department_id)
        REFERENCES departments(id)
        ON DELETE CASCADE,

    CONSTRAINT check_dates
        CHECK (end_date IS NULL OR end_date >= start_date),

    CONSTRAINT check_status
        CHECK (status IN ('planning', 'active', 'completed', 'cancelled'))
);

-- 1-4. employee_projects (직원-프로젝트 매핑) 테이블
CREATE TABLE employee_projects (
    employee_id INTEGER,
    project_id INTEGER,
    role VARCHAR(50),
    assigned_date DATE DEFAULT CURRENT_DATE,
    hours_allocated DECIMAL(5, 2),

    PRIMARY KEY (employee_id, project_id),

    CONSTRAINT fk_ep_employee
        FOREIGN KEY (employee_id)
        REFERENCES employees(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_ep_project
        FOREIGN KEY (project_id)
        REFERENCES projects(id)
        ON DELETE CASCADE
);

-- 테이블 구조 확인
\dt

-- ====================================
-- 과제 2: 데이터 삽입
-- ====================================

-- 2-1. 부서 데이터 삽입
INSERT INTO departments (name, location) VALUES
    ('Engineering', 'Seoul'),
    ('Marketing', 'Busan'),
    ('Sales', 'Seoul'),
    ('HR', 'Incheon'),
    ('Finance', 'Seoul');

-- 2-2. 직원 데이터 삽입
INSERT INTO employees (employee_number, first_name, last_name, email, phone, hire_date, salary, department_id) VALUES
    ('EMP001', 'John', 'Doe', 'john.doe@company.com', '010-1234-5678', '2020-01-15', 80000.00, 1),
    ('EMP002', 'Jane', 'Smith', 'jane.smith@company.com', '010-2345-6789', '2020-03-20', 75000.00, 1),
    ('EMP003', 'Bob', 'Wilson', 'bob.wilson@company.com', '010-3456-7890', '2019-06-10', 85000.00, 1),
    ('EMP004', 'Alice', 'Brown', 'alice.brown@company.com', '010-4567-8901', '2021-02-01', 65000.00, 2),
    ('EMP005', 'Charlie', 'Davis', 'charlie.davis@company.com', '010-5678-9012', '2021-05-15', 70000.00, 2),
    ('EMP006', 'Diana', 'Miller', 'diana.miller@company.com', '010-6789-0123', '2018-08-20', 90000.00, 3),
    ('EMP007', 'Eve', 'Garcia', 'eve.garcia@company.com', '010-7890-1234', '2022-01-10', 60000.00, 3),
    ('EMP008', 'Frank', 'Martinez', 'frank.martinez@company.com', '010-8901-2345', '2020-11-05', 72000.00, 4),
    ('EMP009', 'Grace', 'Lopez', 'grace.lopez@company.com', '010-9012-3456', '2019-04-12', 78000.00, 4),
    ('EMP010', 'Henry', 'Lee', 'henry.lee@company.com', '010-0123-4567', '2021-09-25', 68000.00, 5);

-- 2-3. 매니저 설정 (자기 자신을 참조하므로 별도 업데이트)
UPDATE employees SET manager_id = 3 WHERE id IN (1, 2);
UPDATE employees SET manager_id = 5 WHERE id = 4;
UPDATE employees SET manager_id = 6 WHERE id = 7;
UPDATE employees SET manager_id = 9 WHERE id = 8;

-- 2-4. 프로젝트 데이터 삽입
INSERT INTO projects (name, description, start_date, end_date, budget, status, department_id) VALUES
    ('Website Redesign', 'Complete overhaul of company website', '2024-01-01', '2024-06-30', 150000.00, 'active', 1),
    ('Mobile App Development', 'New iOS and Android app', '2024-02-01', NULL, 200000.00, 'active', 1),
    ('Marketing Campaign Q1', 'Q1 2024 marketing initiatives', '2024-01-01', '2024-03-31', 50000.00, 'completed', 2),
    ('Sales Training Program', 'Comprehensive sales training', '2024-03-01', '2024-05-31', 30000.00, 'active', 3),
    ('HR System Upgrade', 'Upgrade HR management system', '2024-04-01', NULL, 80000.00, 'planning', 4);

-- 2-5. 직원-프로젝트 매핑
INSERT INTO employee_projects (employee_id, project_id, role, hours_allocated) VALUES
    (1, 1, 'Developer', 160.00),
    (2, 1, 'Designer', 120.00),
    (3, 2, 'Tech Lead', 180.00),
    (1, 2, 'Developer', 80.00),
    (4, 3, 'Campaign Manager', 160.00),
    (5, 3, 'Content Writer', 140.00),
    (6, 4, 'Trainer', 100.00),
    (7, 4, 'Coordinator', 120.00),
    (8, 5, 'Project Manager', 160.00);

-- ====================================
-- 과제 3: 기본 쿼리 작성
-- ====================================

-- 3-1. 모든 직원의 이름과 이메일 조회
SELECT first_name, last_name, email FROM employees;

-- 3-2. 급여가 70000 이상인 직원 조회
SELECT first_name, last_name, salary
FROM employees
WHERE salary >= 70000
ORDER BY salary DESC;

-- 3-3. Engineering 부서의 직원 수
SELECT COUNT(*) as engineer_count
FROM employees e
JOIN departments d ON e.department_id = d.id
WHERE d.name = 'Engineering';

-- 3-4. 부서별 평균 급여 (높은 순)
SELECT
    d.name as department,
    COUNT(e.id) as employee_count,
    ROUND(AVG(e.salary), 2) as avg_salary,
    MIN(e.salary) as min_salary,
    MAX(e.salary) as max_salary
FROM departments d
LEFT JOIN employees e ON d.id = e.department_id
GROUP BY d.id, d.name
ORDER BY avg_salary DESC NULLS LAST;

-- 3-5. 2020년에 입사한 직원들
SELECT first_name, last_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020
ORDER BY hire_date;

-- 3-6. 이름에 'a'가 포함된 직원들
SELECT first_name, last_name
FROM employees
WHERE LOWER(first_name) LIKE '%a%'
   OR LOWER(last_name) LIKE '%a%';

-- 3-7. 가장 최근에 입사한 5명의 직원
SELECT first_name, last_name, hire_date
FROM employees
ORDER BY hire_date DESC
LIMIT 5;

-- 3-8. 프로젝트가 없는 직원 찾기
SELECT e.first_name, e.last_name
FROM employees e
LEFT JOIN employee_projects ep ON e.id = ep.employee_id
WHERE ep.employee_id IS NULL;

-- ====================================
-- 과제 4: 고급 쿼리 (도전!)
-- ====================================

-- 4-1. 각 직원의 이름, 부서명, 매니저 이름
SELECT
    e.first_name || ' ' || e.last_name as employee_name,
    d.name as department,
    m.first_name || ' ' || m.last_name as manager_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.id
LEFT JOIN employees m ON e.manager_id = m.id
ORDER BY e.id;

-- 4-2. 프로젝트별 참여 직원 수와 총 할당 시간
SELECT
    p.name as project,
    COUNT(ep.employee_id) as team_size,
    SUM(ep.hours_allocated) as total_hours,
    p.budget,
    p.status
FROM projects p
LEFT JOIN employee_projects ep ON p.id = ep.project_id
GROUP BY p.id, p.name, p.budget, p.status
ORDER BY total_hours DESC NULLS LAST;

-- 4-3. 급여 상위 10% 직원들
SELECT
    first_name,
    last_name,
    salary,
    PERCENT_RANK() OVER (ORDER BY salary DESC) as salary_percentile
FROM employees
WHERE PERCENT_RANK() OVER (ORDER BY salary DESC) <= 0.10;

-- 또는 간단하게:
SELECT first_name, last_name, salary
FROM employees
ORDER BY salary DESC
LIMIT (SELECT CEIL(COUNT(*) * 0.1) FROM employees);

-- 4-4. 부서별 급여 순위
SELECT
    d.name as department,
    e.first_name || ' ' || e.last_name as employee_name,
    e.salary,
    RANK() OVER (PARTITION BY d.id ORDER BY e.salary DESC) as dept_rank
FROM employees e
JOIN departments d ON e.department_id = d.id
ORDER BY d.name, dept_rank;

-- 4-5. 근속 기간 계산
SELECT
    first_name,
    last_name,
    hire_date,
    AGE(CURRENT_DATE, hire_date) as tenure,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)) as years_of_service
FROM employees
ORDER BY hire_date;

-- ====================================
-- 과제 5: 데이터 수정
-- ====================================

-- 5-1. 모든 직원의 급여를 5% 인상
BEGIN;
UPDATE employees
SET salary = salary * 1.05,
    updated_at = CURRENT_TIMESTAMP;
-- ROLLBACK; -- 실제로 적용하지 않으려면 ROLLBACK
COMMIT;

-- 5-2. Engineering 부서의 급여를 추가로 3% 인상
BEGIN;
UPDATE employees e
SET salary = salary * 1.03,
    updated_at = CURRENT_TIMESTAMP
FROM departments d
WHERE e.department_id = d.id
  AND d.name = 'Engineering';
COMMIT;

-- 5-3. 완료된 프로젝트에서 직원 할당 제거 (아카이빙)
DELETE FROM employee_projects
WHERE project_id IN (
    SELECT id FROM projects WHERE status = 'completed'
);

-- ====================================
-- 과제 6: 실용적인 쿼리
-- ====================================

-- 6-1. 월별 입사자 통계
SELECT
    TO_CHAR(hire_date, 'YYYY-MM') as hire_month,
    COUNT(*) as new_hires,
    ROUND(AVG(salary), 2) as avg_starting_salary
FROM employees
GROUP BY hire_month
ORDER BY hire_month;

-- 6-2. 이메일 도메인별 통계
SELECT
    SUBSTRING(email FROM '@(.*)$') as email_domain,
    COUNT(*) as count
FROM employees
GROUP BY email_domain;

-- 6-3. 프로젝트 예산 대비 인건비 추정
SELECT
    p.name,
    p.budget,
    COUNT(ep.employee_id) as team_size,
    SUM(ep.hours_allocated) as total_hours,
    ROUND(SUM(ep.hours_allocated * e.salary / 2080), 2) as estimated_labor_cost,
    p.budget - ROUND(SUM(ep.hours_allocated * e.salary / 2080), 2) as budget_remaining
FROM projects p
LEFT JOIN employee_projects ep ON p.id = ep.project_id
LEFT JOIN employees e ON ep.employee_id = e.id
GROUP BY p.id, p.name, p.budget
ORDER BY budget_remaining;

-- ====================================
-- 보너스: 유용한 관리 쿼리
-- ====================================

-- 테이블 크기 확인
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- 인덱스 목록
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 제약조건 확인
SELECT
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_type;
