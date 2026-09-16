-- ============================================================
-- Employee Hierarchy & Org Analytics — Day 3
-- Query 1: Headcount per manager (direct + indirect reports)
-- ============================================================
-- Strategy: for each employee who manages anyone, count how many
-- employees appear in their downstream subtree. We build this by
-- generating, for every employee, the full list of ancestors above
-- them (a recursive upward walk), then aggregating "how many times
-- does each employee_id appear as someone's ancestor".
-- ============================================================

WITH RECURSIVE ancestors AS (
    -- Anchor: every employee is their own starting point, no ancestor yet
    SELECT
        employee_id AS descendant_id,
        manager_id  AS ancestor_id
    FROM employees
    WHERE manager_id IS NOT NULL

    UNION ALL

    -- Recursive step: climb one more level up the chain
    SELECT
        a.descendant_id,
        e.manager_id
    FROM ancestors a
    JOIN employees e ON a.ancestor_id = e.employee_id
    WHERE e.manager_id IS NOT NULL
)
SELECT
    m.employee_id,
    m.name          AS manager_name,
    m.job_title,
    COUNT(a.descendant_id) AS total_headcount   -- direct + indirect reports
FROM employees m
JOIN ancestors a ON a.ancestor_id = m.employee_id
GROUP BY m.employee_id, m.name, m.job_title
ORDER BY total_headcount DESC;