-- ============================================================
-- Employee Hierarchy & Org Analytics — Day 3
-- Query 2: Salary rollup by hierarchy level (depth)
-- ============================================================
-- Reuses the same depth-computing recursive CTE from Day 2's
-- org chart traversal, then aggregates salary stats per depth.
-- ============================================================

WITH RECURSIVE org_chart AS (
    SELECT
        employee_id, salary, 1 AS depth,
        CAST(employee_id AS TEXT) AS id_path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT
        e.employee_id, e.salary, oc.depth + 1,
        oc.id_path || '>' || CAST(e.employee_id AS TEXT)
    FROM employees e
    JOIN org_chart oc ON e.manager_id = oc.employee_id
    WHERE oc.id_path NOT LIKE '%' || CAST(e.employee_id AS TEXT) || '%'
)
SELECT
    depth,
    COUNT(*)                     AS employee_count,
    SUM(salary)                  AS total_salary,
    ROUND(AVG(salary), 2)        AS avg_salary,
    MIN(salary)                  AS min_salary,
    MAX(salary)                  AS max_salary
FROM org_chart
GROUP BY depth
ORDER BY depth;