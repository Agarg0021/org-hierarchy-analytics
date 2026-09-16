-- ============================================================
-- Employee Hierarchy & Org Analytics — Day 3
-- Query 3: Subtree salary rollup — total comp cost of each manager's
--          entire downstream org (their own salary + every report,
--          direct and indirect)
-- ============================================================
-- Builds on the same ancestor-walk approach as Query 1: for every
-- employee, list all of their ancestors. Summing salary grouped by
-- ancestor_id gives the total downstream cost per manager. We then
-- add the manager's own salary back in for a fully-loaded subtree cost.
-- ============================================================

WITH RECURSIVE ancestors AS (
    SELECT employee_id AS descendant_id, manager_id AS ancestor_id
    FROM employees
    WHERE manager_id IS NOT NULL

    UNION ALL

    SELECT a.descendant_id, e.manager_id
    FROM ancestors a
    JOIN employees e ON a.ancestor_id = e.employee_id
    WHERE e.manager_id IS NOT NULL
),
downstream_cost AS (
    SELECT
        a.ancestor_id AS manager_id,
        SUM(e.salary) AS reports_salary_total,
        COUNT(*)      AS reports_count
    FROM ancestors a
    JOIN employees e ON a.descendant_id = e.employee_id
    GROUP BY a.ancestor_id
)
SELECT
    m.employee_id,
    m.name        AS manager_name,
    m.job_title,
    m.salary      AS manager_own_salary,
    dc.reports_count,
    dc.reports_salary_total,
    m.salary + dc.reports_salary_total AS full_subtree_cost
FROM employees m
JOIN downstream_cost dc ON dc.manager_id = m.employee_id
ORDER BY full_subtree_cost DESC;