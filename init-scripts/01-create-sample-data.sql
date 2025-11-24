-- ====================================
-- PostgreSQL 학습용 샘플 데이터
-- ====================================

-- 데이터베이스 생성 (외부에서 실행)
-- CREATE DATABASE learning_db;

\c learning_db

-- ====================================
-- 샘플 스키마 생성
-- ====================================

-- 부서 테이블
CREATE TABLE IF NOT EXISTS departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    location VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 직원 테이블
CREATE TABLE IF NOT EXISTS employees (
    id SERIAL PRIMARY KEY,
    employee_number VARCHAR(10) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    hire_date DATE NOT NULL,
    salary DECIMAL(10, 2) CHECK (salary > 0),
    department_id INTEGER REFERENCES departments(id),
    manager_id INTEGER REFERENCES employees(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 프로젝트 테이블
CREATE TABLE IF NOT EXISTS projects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    budget DECIMAL(12, 2),
    status VARCHAR(20) DEFAULT 'planning',
    department_id INTEGER REFERENCES departments(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_dates CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT check_status CHECK (status IN ('planning', 'active', 'completed', 'cancelled'))
);

-- 직원-프로젝트 매핑 테이블
CREATE TABLE IF NOT EXISTS employee_projects (
    employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    role VARCHAR(50),
    assigned_date DATE DEFAULT CURRENT_DATE,
    hours_allocated DECIMAL(5, 2),
    PRIMARY KEY (employee_id, project_id)
);

-- ====================================
-- 샘플 데이터 삽입
-- ====================================

-- 부서 데이터
INSERT INTO departments (name, location) VALUES
    ('Engineering', 'Seoul'),
    ('Marketing', 'Busan'),
    ('Sales', 'Seoul'),
    ('HR', 'Incheon'),
    ('Finance', 'Seoul')
ON CONFLICT (name) DO NOTHING;

-- 직원 데이터
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
    ('EMP010', 'Henry', 'Lee', 'henry.lee@company.com', '010-0123-4567', '2021-09-25', 68000.00, 5)
ON CONFLICT (email) DO NOTHING;

-- 매니저 설정
UPDATE employees SET manager_id = 3 WHERE id IN (1, 2);
UPDATE employees SET manager_id = 5 WHERE id = 4;
UPDATE employees SET manager_id = 6 WHERE id = 7;
UPDATE employees SET manager_id = 9 WHERE id = 8;

-- 프로젝트 데이터
INSERT INTO projects (name, description, start_date, end_date, budget, status, department_id) VALUES
    ('Website Redesign', 'Complete overhaul of company website', '2024-01-01', '2024-06-30', 150000.00, 'active', 1),
    ('Mobile App Development', 'New iOS and Android app', '2024-02-01', NULL, 200000.00, 'active', 1),
    ('Marketing Campaign Q1', 'Q1 2024 marketing initiatives', '2024-01-01', '2024-03-31', 50000.00, 'completed', 2),
    ('Sales Training Program', 'Comprehensive sales training', '2024-03-01', '2024-05-31', 30000.00, 'active', 3),
    ('HR System Upgrade', 'Upgrade HR management system', '2024-04-01', NULL, 80000.00, 'planning', 4)
ON CONFLICT DO NOTHING;

-- 직원-프로젝트 매핑
INSERT INTO employee_projects (employee_id, project_id, role, hours_allocated) VALUES
    (1, 1, 'Developer', 160.00),
    (2, 1, 'Designer', 120.00),
    (3, 2, 'Tech Lead', 180.00),
    (1, 2, 'Developer', 80.00),
    (4, 3, 'Campaign Manager', 160.00),
    (5, 3, 'Content Writer', 140.00),
    (6, 4, 'Trainer', 100.00),
    (7, 4, 'Coordinator', 120.00),
    (8, 5, 'Project Manager', 160.00)
ON CONFLICT DO NOTHING;

-- ====================================
-- 인덱스 생성
-- ====================================

CREATE INDEX IF NOT EXISTS idx_employees_department ON employees(department_id);
CREATE INDEX IF NOT EXISTS idx_employees_manager ON employees(manager_id);
CREATE INDEX IF NOT EXISTS idx_employees_email ON employees(email);
CREATE INDEX IF NOT EXISTS idx_projects_department ON projects(department_id);
CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status);

-- ====================================
-- 통계 정보 확인용 뷰
-- ====================================

CREATE OR REPLACE VIEW department_stats AS
SELECT
    d.name as department,
    COUNT(e.id) as employee_count,
    COALESCE(AVG(e.salary), 0) as avg_salary,
    COALESCE(SUM(e.salary), 0) as total_salary,
    COUNT(p.id) as active_projects
FROM departments d
LEFT JOIN employees e ON d.id = e.department_id AND e.is_active = TRUE
LEFT JOIN projects p ON d.id = p.department_id AND p.status = 'active'
GROUP BY d.id, d.name;

-- ====================================
-- 샘플 데이터 확인
-- ====================================

SELECT 'Departments created: ' || COUNT(*) FROM departments;
SELECT 'Employees created: ' || COUNT(*) FROM employees;
SELECT 'Projects created: ' || COUNT(*) FROM projects;

\echo '✅ Sample data loaded successfully!'
\echo '📊 Try: SELECT * FROM department_stats;'
