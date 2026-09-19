-- ============================================================
-- Employee Hierarchy & Org Analytics — Day 5
-- View 1: org_chart_view
-- ============================================================
-- Wraps the Day 2 full-org-chart recursive CTE as a reusable view,
-- so consumers can just `SELECT * FROM org_chart_view` instead of
-- re-pasting the recursive CTE everywhere it's needed.
-- ============================================================

DROP VIEW IF EXISTS org_chart_view;

CREATE VIEW org_chart_view AS
WITH RECURSIVE org_chart AS (
    SELECT
        employee_id,
        name,
        manager_id,
        job_title,
        department_id,
        salary,
        1 AS depth,
        CAST(employee_id AS TEXT) AS id_path,
        name AS reporting_chain
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT
        e.employee_id,
        e.name,
        e.manager_id,
        e.job_title,
        e.department_id,
        e.salary,
        oc.depth + 1,
        oc.id_path || '>' || CAST(e.employee_id AS TEXT),
        oc.reporting_chain || ' > ' || e.name
    FROM employees e
    JOIN org_chart oc ON e.manager_id = oc.employee_id
    WHERE oc.id_path NOT LIKE '%' || CAST(e.employee_id AS TEXT) || '%'
)
SELECT
    employee_id,
    name,
    manager_id,
    job_title,
    department_id,
    salary,
    depth,
    reporting_chain
FROM org_chart;

-- ------------------------------------------------------------
-- Example usage:
-- ------------------------------------------------------------
-- SELECT * FROM org_chart_view ORDER BY depth, reporting_chain;
-- SELECT * FROM org_chart_view WHERE depth = 3;                 -- all Directors
-- SELECT department_id, AVG(salary) FROM org_chart_view GROUP BY department_id;