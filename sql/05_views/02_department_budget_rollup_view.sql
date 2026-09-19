-- ============================================================
-- Employee Hierarchy & Org Analytics — Day 5
-- View 2: department_budget_rollup_view
-- ============================================================
-- Wraps the Day 3 department budget variance query as a reusable
-- view.
-- ============================================================

DROP VIEW IF EXISTS department_budget_rollup_view;

CREATE VIEW department_budget_rollup_view AS
SELECT
    d.department_id,
    d.department_name,
    COUNT(e.employee_id)                       AS headcount,
    SUM(e.salary)                               AS total_salary_spend,
    d.budget                                    AS allocated_budget,
    d.budget - SUM(e.salary)                    AS variance,
    ROUND(100.0 * SUM(e.salary) / d.budget, 1)  AS pct_of_budget_used,
    CASE
        WHEN SUM(e.salary) > d.budget THEN 'OVER BUDGET'
        ELSE 'UNDER BUDGET'
    END AS status
FROM departments d
JOIN employees e ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name, d.budget;

-- ------------------------------------------------------------
-- Example usage:
-- ------------------------------------------------------------
-- SELECT * FROM department_budget_rollup_view ORDER BY variance ASC;
-- SELECT * FROM department_budget_rollup_view WHERE status = 'OVER BUDGET';