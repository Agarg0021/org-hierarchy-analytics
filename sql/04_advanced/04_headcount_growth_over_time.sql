-- ============================================================
-- Employee Hierarchy & Org Analytics — Day 4
-- Query 4: Cumulative headcount growth over time, per department
-- ============================================================
-- Not recursive — this uses hire_date with a window function to
-- show org size growth over time, complementing the recursive
-- hierarchy queries with a time dimension.
-- ============================================================

WITH hires_by_year AS (
    SELECT
        d.department_name,
        CAST(strftime('%Y', e.hire_date) AS INTEGER) AS hire_year,
        COUNT(*) AS new_hires
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    GROUP BY d.department_name, hire_year
)
SELECT
    department_name,
    hire_year,
    new_hires,
    SUM(new_hires) OVER (
        PARTITION BY department_name
        ORDER BY hire_year
    ) AS cumulative_headcount
FROM hires_by_year
ORDER BY department_name, hire_year;

-- ------------------------------------------------------------
-- Companion: org-wide cumulative headcount over time (all depts combined)
-- ------------------------------------------------------------
WITH hires_by_year_total AS (
    SELECT
        CAST(strftime('%Y', hire_date) AS INTEGER) AS hire_year,
        COUNT(*) AS new_hires
    FROM employees
    GROUP BY hire_year
)
SELECT
    hire_year,
    new_hires,
    SUM(new_hires) OVER (ORDER BY hire_year) AS cumulative_headcount
FROM hires_by_year_total
ORDER BY hire_year;