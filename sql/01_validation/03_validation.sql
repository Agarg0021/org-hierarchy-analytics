-- ============================================================
-- Employee Hierarchy & Org Analytics — Day 1: Validation Queries
-- Run these after loading 01_schema.sql and 02_seed.sql
-- ============================================================

-- 1. Row counts
SELECT 'departments' AS table_name, COUNT(*) AS row_count FROM departments
UNION ALL
SELECT 'employees', COUNT(*) FROM employees;

-- 2. Exactly one root node (CEO with no manager)
SELECT COUNT(*) AS root_count FROM employees WHERE manager_id IS NULL;
-- Expect: 1

-- 3. Orphan check — manager_id values that don't exist as employee_id
SELECT e.employee_id, e.name, e.manager_id
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id
WHERE e.manager_id IS NOT NULL AND m.employee_id IS NULL;
-- Expect: 0 rows

-- 4. Self-reference check — nobody manages themselves
SELECT employee_id, name FROM employees WHERE employee_id = manager_id;
-- Expect: 0 rows

-- 5. Direct-report count per manager (sanity distribution)
SELECT m.name AS manager_name, m.job_title, COUNT(e.employee_id) AS direct_reports
FROM employees m
LEFT JOIN employees e ON e.manager_id = m.employee_id
GROUP BY m.employee_id, m.name, m.job_title
HAVING COUNT(e.employee_id) > 0
ORDER BY direct_reports DESC;

-- 6. Headcount and salary spend per department
SELECT d.department_name,
       COUNT(e.employee_id) AS headcount,
       SUM(e.salary)        AS total_salary,
       d.budget,
       d.budget - SUM(e.salary) AS budget_remaining
FROM departments d
JOIN employees e ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name, d.budget
ORDER BY d.department_name;

-- 7. Basic cycle check via bounded-depth recursive walk
--    (If any employee is unreachable within a generous depth bound, or
--     the recursion doesn't terminate, that signals a cycle.)
WITH RECURSIVE reachable AS (
    SELECT employee_id, 1 AS depth
    FROM employees WHERE manager_id IS NULL
    UNION ALL
    SELECT e.employee_id, r.depth + 1
    FROM employees e
    JOIN reachable r ON e.manager_id = r.employee_id
    WHERE r.depth < 20  -- guard bound
)
SELECT
    (SELECT COUNT(*) FROM employees) AS total_employees,
    (SELECT COUNT(DISTINCT employee_id) FROM reachable) AS reachable_employees;
-- Expect: total_employees == reachable_employees
