-- ============================================================
-- Employee Hierarchy & Org Analytics — Day 4
-- Query 3: Highest-paid person per subtree + salary inversion flags
-- ============================================================
-- Part A: for every manager, find the highest-paid person anywhere
--         in their downstream subtree (not just direct reports).
-- Part B: flag direct-report salary inversions, where an employee
--         earns more than their own direct manager.
-- ============================================================

-- ---- Part A: highest-paid person in each subtree ----
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
subtree_max AS (
    SELECT
        a.ancestor_id AS manager_id,
        e.employee_id AS top_earner_id,
        e.name        AS top_earner_name,
        e.salary      AS top_earner_salary,
        ROW_NUMBER() OVER (
            PARTITION BY a.ancestor_id ORDER BY e.salary DESC
        ) AS rn
    FROM ancestors a
    JOIN employees e ON a.descendant_id = e.employee_id
)
SELECT
    m.employee_id,
    m.name       AS manager_name,
    m.salary     AS manager_salary,
    sm.top_earner_name,
    sm.top_earner_salary,
    sm.top_earner_salary - m.salary AS gap_vs_manager
FROM employees m
JOIN subtree_max sm ON sm.manager_id = m.employee_id AND sm.rn = 1
ORDER BY gap_vs_manager DESC;

-- ---- Part B: direct-report salary inversions ----
-- (An inversion here = a direct report earning more than their own
--  direct manager. Part A above is broader: it can surface someone
--  several levels down out-earning a manager without necessarily
--  being a direct-report inversion.)
SELECT
    e.employee_id      AS employee_id,
    e.name             AS employee_name,
    e.job_title        AS employee_title,
    e.salary           AS employee_salary,
    m.employee_id      AS manager_id,
    m.name             AS manager_name,
    m.job_title        AS manager_title,
    m.salary           AS manager_salary,
    e.salary - m.salary AS inversion_amount
FROM employees e
JOIN employees m ON e.manager_id = m.employee_id
WHERE e.salary > m.salary
ORDER BY inversion_amount DESC;