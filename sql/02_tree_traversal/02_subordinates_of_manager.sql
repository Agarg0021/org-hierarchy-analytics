-- ============================================================
-- Employee Hierarchy & Org Analytics — Day 2
-- Query 2: All subordinates (direct + indirect) of a given manager
-- ============================================================
-- Anchor member:    the manager whose ID we're starting from
--                    (relative depth = 0, not included in final output)
-- Recursive member: each employee reporting up the chain to that
--                    manager, relative depth incrementing each level
--
-- Usage: replace :manager_id with the employee_id to look up.
-- In SQLite CLI: run with `.parameter set :manager_id 5` or inline
-- the literal value as shown below.
-- ============================================================

WITH RECURSIVE subordinates AS (
    -- Anchor: the manager themself (depth 0, excluded from results)
    SELECT
        employee_id,
        name,
        manager_id,
        job_title,
        salary,
        0 AS relative_depth
    FROM employees
    WHERE employee_id = :manager_id          -- <-- parameter: manager to look up

    UNION ALL

    -- Recursive step: everyone reporting (directly or indirectly) to them
    SELECT
        e.employee_id,
        e.name,
        e.manager_id,
        e.job_title,
        e.salary,
        s.relative_depth + 1
    FROM employees e
    JOIN subordinates s ON e.manager_id = s.employee_id
)
SELECT
    employee_id,
    name,
    job_title,
    salary,
    relative_depth
FROM subordinates
WHERE relative_depth > 0                     -- exclude the manager themself
ORDER BY relative_depth, name;

-- ------------------------------------------------------------
-- Example (literal, SQLite-runnable): all subordinates of employee_id = 2
-- ------------------------------------------------------------
-- WITH RECURSIVE subordinates AS (
--     SELECT employee_id, name, manager_id, job_title, salary, 0 AS relative_depth
--     FROM employees WHERE employee_id = 2
--     UNION ALL
--     SELECT e.employee_id, e.name, e.manager_id, e.job_title, e.salary, s.relative_depth + 1
--     FROM employees e JOIN subordinates s ON e.manager_id = s.employee_id
-- )
-- SELECT employee_id, name, job_title, salary, relative_depth
-- FROM subordinates WHERE relative_depth > 0
-- ORDER BY relative_depth, name;
