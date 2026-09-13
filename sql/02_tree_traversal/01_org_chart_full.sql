-- ============================================================
-- Employee Hierarchy & Org Analytics — Day 2
-- Query 1: Full org chart — top-down traversal with reporting depth
-- ============================================================
-- Anchor member:    the root (CEO), manager_id IS NULL, depth = 1
-- Recursive member: each employee whose manager was found in the
--                    previous step, depth = parent depth + 1
-- Cycle guard:       `path` accumulates visited IDs; the recursive
--                    join excludes any employee already present in
--                    the current path, so a corrupted manager_id
--                    loop cannot cause infinite recursion.
-- ============================================================

WITH RECURSIVE org_chart AS (
    -- Anchor: the CEO (or any employee with no manager)
    SELECT
        employee_id,
        name,
        manager_id,
        job_title,
        department_id,
        salary,
        1 AS depth,
        CAST(employee_id AS TEXT) AS id_path,        -- for cycle detection
        name AS name_path                            -- human-readable breadcrumb
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive step: walk down to each direct report
    SELECT
        e.employee_id,
        e.name,
        e.manager_id,
        e.job_title,
        e.department_id,
        e.salary,
        oc.depth + 1,
        oc.id_path || '>' || CAST(e.employee_id AS TEXT),
        oc.name_path || ' > ' || e.name
    FROM employees e
    JOIN org_chart oc ON e.manager_id = oc.employee_id
    -- cycle guard: stop if this employee_id already appears upstream
    WHERE oc.id_path NOT LIKE '%' || CAST(e.employee_id AS TEXT) || '%'
)
SELECT
    employee_id,
    name,
    job_title,
    department_id,
    salary,
    depth,
    name_path AS reporting_chain
FROM org_chart
ORDER BY depth, name_path;
