-- ============================================================
-- Employee Hierarchy & Org Analytics — Day 2
-- Query 3: Upward traversal — an employee's full management chain to the CEO
-- ============================================================
-- Anchor member:    the starting employee (level 0)
-- Recursive member: walk to manager_id each step, level incrementing,
--                    stopping naturally when manager_id IS NULL (CEO)
--
-- Usage: replace :employee_id with the employee_id to look up.
-- ============================================================

WITH RECURSIVE chain_up AS (
    -- Anchor: the employee themself
    SELECT
        employee_id,
        name,
        manager_id,
        job_title,
        0 AS level
    FROM employees
    WHERE employee_id = :employee_id          -- <-- parameter: employee to trace

    UNION ALL

    -- Recursive step: move up to the manager
    SELECT
        e.employee_id,
        e.name,
        e.manager_id,
        e.job_title,
        c.level + 1
    FROM employees e
    JOIN chain_up c ON e.employee_id = c.manager_id
)
SELECT
    level,
    employee_id,
    name,
    job_title
FROM chain_up
ORDER BY level;

-- ------------------------------------------------------------
-- Example (literal, SQLite-runnable): management chain for employee_id = 50
-- ------------------------------------------------------------
-- WITH RECURSIVE chain_up AS (
--     SELECT employee_id, name, manager_id, job_title, 0 AS level
--     FROM employees WHERE employee_id = 50
--     UNION ALL
--     SELECT e.employee_id, e.name, e.manager_id, e.job_title, c.level + 1
--     FROM employees e JOIN chain_up c ON e.employee_id = c.manager_id
-- )
-- SELECT level, employee_id, name, job_title
-- FROM chain_up ORDER BY level;
