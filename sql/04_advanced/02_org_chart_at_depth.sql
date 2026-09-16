-- ============================================================
-- Employee Hierarchy & Org Analytics — Day 4
-- Query 2: Org chart filtered to a specific depth level
-- ============================================================
-- Reuses the Day 2 depth-computing CTE, then filters to just one
-- level — e.g. "show me everyone at level 3" (all Directors).
--
-- Usage: replace :target_depth with the level to view (1 = CEO,
-- 2 = VPs, 3 = Directors, 4 = Managers, 5 = ICs in this dataset).
-- ============================================================

WITH RECURSIVE org_chart AS (
    SELECT
        employee_id, name, job_title, department_id, salary,
        1 AS depth, CAST(employee_id AS TEXT) AS id_path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT
        e.employee_id, e.name, e.job_title, e.department_id, e.salary,
        oc.depth + 1, oc.id_path || '>' || CAST(e.employee_id AS TEXT)
    FROM employees e
    JOIN org_chart oc ON e.manager_id = oc.employee_id
    WHERE oc.id_path NOT LIKE '%' || CAST(e.employee_id AS TEXT) || '%'
)
SELECT
    employee_id, name, job_title, department_id, salary, depth
FROM org_chart
WHERE depth = :target_depth               -- <-- parameter: level to filter to
ORDER BY department_id, name;

-- ------------------------------------------------------------
-- Example (literal, SQLite-runnable): everyone at depth 3 (Directors)
-- ------------------------------------------------------------
-- WITH RECURSIVE org_chart AS (
--     SELECT employee_id, name, job_title, department_id, salary,
--            1 AS depth, CAST(employee_id AS TEXT) AS id_path
--     FROM employees WHERE manager_id IS NULL
--     UNION ALL
--     SELECT e.employee_id, e.name, e.job_title, e.department_id, e.salary,
--            oc.depth + 1, oc.id_path || '>' || CAST(e.employee_id AS TEXT)
--     FROM employees e JOIN org_chart oc ON e.manager_id = oc.employee_id
--     WHERE oc.id_path NOT LIKE '%' || CAST(e.employee_id AS TEXT) || '%'
-- )
-- SELECT employee_id, name, job_title, department_id, salary, depth
-- FROM org_chart WHERE depth = 3
-- ORDER BY department_id, name;