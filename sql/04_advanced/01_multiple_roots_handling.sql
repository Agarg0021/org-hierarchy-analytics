-- ============================================================
-- Employee Hierarchy & Org Analytics — Day 4
-- Query 1: Detect and handle multiple root nodes
-- ============================================================
-- Our current dataset has exactly one root (the CEO, manager_id
-- IS NULL). Real HR data is messier: a second co-CEO, a
-- disconnected/orphaned employee record, or a data-entry error can
-- silently create extra roots. If the Day 2 org_chart CTE anchors
-- on "WHERE manager_id IS NULL" without accounting for this, extra
-- roots are included automatically (which is usually fine) but they
-- can also mask bad data if unnoticed. This query surfaces them
-- explicitly rather than assuming there's exactly one.
-- ============================================================

-- Step 1: identify all root candidates and how large each of their
-- trees is, so multiple real roots vs. one accidental orphan are
-- easy to tell apart.
WITH RECURSIVE org_chart AS (
    SELECT
        employee_id,
        employee_id AS root_id,   -- track which root this row descends from
        name        AS root_name,
        1 AS depth,
        CAST(employee_id AS TEXT) AS id_path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT
        e.employee_id,
        oc.root_id,
        oc.root_name,
        oc.depth + 1,
        oc.id_path || '>' || CAST(e.employee_id AS TEXT)
    FROM employees e
    JOIN org_chart oc ON e.manager_id = oc.employee_id
    WHERE oc.id_path NOT LIKE '%' || CAST(e.employee_id AS TEXT) || '%'
)
SELECT
    root_id,
    root_name,
    COUNT(*)      AS tree_size,
    MAX(depth)    AS max_depth_in_tree
FROM org_chart
GROUP BY root_id, root_name
ORDER BY tree_size DESC;

-- ------------------------------------------------------------
-- Companion check: employees who reference a manager_id that
-- doesn't exist in the table at all (true data-quality orphans,
-- distinct from legitimate secondary roots).
-- ------------------------------------------------------------
SELECT e.employee_id, e.name, e.manager_id
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id
WHERE e.manager_id IS NOT NULL AND m.employee_id IS NULL;
-- Expect 0 rows on clean data; if not empty, these employees are
-- invisible to any top-down traversal starting from manager_id IS NULL
-- and need a data-fix decision (attach to a real manager, or null it out
-- to make them a recognized second root).