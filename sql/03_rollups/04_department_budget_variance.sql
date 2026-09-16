-- ============================================================
-- Employee Hierarchy & Org Analytics — Day 3
-- Query 4: Department budget aggregation & variance
-- ============================================================
-- Straightforward join + aggregate: total actual salary spend per
-- department vs. its allocated budget, with variance and a status
-- flag. No recursion needed here since department is a flat
-- attribute on employees — but it complements the hierarchy rollups
-- by rolling salaries up along the *other* axis (department, not
-- reporting line).
-- ============================================================

SELECT
    d.department_id,
    d.department_name,
    COUNT(e.employee_id)          AS headcount,
    SUM(e.salary)                 AS total_salary_spend,
    d.budget                      AS allocated_budget,
    d.budget - SUM(e.salary)      AS variance,
    ROUND(100.0 * SUM(e.salary) / d.budget, 1) AS pct_of_budget_used,
    CASE
        WHEN SUM(e.salary) > d.budget THEN 'OVER BUDGET'
        ELSE 'UNDER BUDGET'
    END AS status
FROM departments d
JOIN employees e ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name, d.budget
ORDER BY variance ASC;   -- most over-budget departments first