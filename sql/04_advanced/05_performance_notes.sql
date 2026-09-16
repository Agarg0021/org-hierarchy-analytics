-- ============================================================
-- Employee Hierarchy & Org Analytics — Day 4
-- Query 5: Performance analysis — EXPLAIN QUERY PLAN + indexing
-- ============================================================
-- SQLite uses EXPLAIN QUERY PLAN (no ANALYZE timing built in the
-- same way Postgres's EXPLAIN ANALYZE provides). On Postgres, swap
-- the command for: EXPLAIN ANALYZE <query>
-- ============================================================

-- 1. Check the plan for the Day 2 full org chart traversal
EXPLAIN QUERY PLAN
WITH RECURSIVE org_chart AS (
    SELECT employee_id, manager_id, 1 AS depth,
           CAST(employee_id AS TEXT) AS id_path
    FROM employees WHERE manager_id IS NULL
    UNION ALL
    SELECT e.employee_id, e.manager_id, oc.depth + 1,
           oc.id_path || '>' || CAST(e.employee_id AS TEXT)
    FROM employees e
    JOIN org_chart oc ON e.manager_id = oc.employee_id
    WHERE oc.id_path NOT LIKE '%' || CAST(e.employee_id AS TEXT) || '%'
)
SELECT * FROM org_chart;

-- 2. Check the plan for the Day 3 department budget variance query
EXPLAIN QUERY PLAN
SELECT d.department_id, SUM(e.salary)
FROM departments d
JOIN employees e ON e.department_id = d.department_id
GROUP BY d.department_id;

-- ------------------------------------------------------------
-- Indexing notes
-- ------------------------------------------------------------
-- Indexes already created in 01_schema.sql:
--   idx_employees_manager_id    ON employees(manager_id)
--   idx_employees_department_id ON employees(department_id)
--
-- Why these matter:
-- - manager_id: every recursive CTE's recursive member joins
--   `employees e ON e.manager_id = <parent>.employee_id`. Without
--   an index on manager_id, each recursive step does a full table
--   scan to find an employee's children. At 127 rows this is
--   invisible; at 100K+ rows it becomes the dominant cost.
-- - department_id: used by every department rollup (Day 3 Query 4,
--   Day 4 Query 4). Without it, grouping/joining on department
--   requires a full scan per department lookup.
--
-- Actual EXPLAIN QUERY PLAN output on this dataset (127 rows):
--
--   Org chart traversal (Query 1 above):
--     SEARCH employees USING COVERING INDEX idx_employees_manager_id (manager_id=?)   -- anchor
--     RECURSIVE STEP
--     SEARCH e USING COVERING INDEX idx_employees_manager_id (manager_id=?)           -- recursive join
--
--   Department budget aggregation (Query 2 above):
--     SEARCH e USING INDEX idx_employees_department_id (department_id=?)
--
-- Both indexes are already being used at this small scale, not just
-- projected to help later — SQLite's planner picks the index-backed
-- search over a full scan even at 127 rows because manager_id and
-- department_id are far from unique-per-row, making the index the
-- cheaper path either way. The benefit becomes more pronounced (and
-- necessary) as row count grows into the thousands: without these
-- indexes, each recursive step and each department join would
-- degrade toward an O(n) scan per lookup instead of an O(log n)
-- index search.