# Employee Hierarchy & Org Analytics

Recursive CTE showcase over an HR dataset with a self-referencing
`manager_id` / `employee_id` structure. Builds org trees, reporting
depth, salary rollups, and subordinate/manager lookups using
`WITH RECURSIVE`.

## Folder Structure

```
sql/00_setup/           Schema + seed data (run these first, in order)
sql/01_validation/      Sanity checks: single root, no orphans, no cycles
sql/02_tree_traversal/  Top-down org chart, subordinates-of-manager, upward chain
sql/03_rollups/         Headcount, salary-by-depth, subtree rollups, budget variance
sql/04_advanced/        Depth filters, salary inversions, growth over time, perf notes
sql/05_views/           Reusable CREATE VIEW wrappers around the most-used queries

scripts/                Python data generator
data/                   SQLite database with schema + seed already loaded
reports/                Exported results (CSV, diagrams)
docs/                   ERD / supporting diagrams
```

## Setup

Everything is already loaded into `data/org.db`. To rebuild from scratch:

```bash
sqlite3 data/org.db < sql/00_setup/01_schema.sql
sqlite3 data/org.db < sql/00_setup/02_seed.sql
sqlite3 data/org.db < sql/01_validation/03_validation.sql
```

Or regenerate the seed data itself (127 employees, 4 departments, 5 levels):

```bash
python3 scripts/generate_seed.py
```

## Dataset

- **departments**: `department_id, department_name, budget`
- **employees**: `employee_id, name, manager_id, department_id, job_title, salary, hire_date`
- 1 CEO (root, `manager_id IS NULL`) → VPs → Directors → Managers → ICs
- 127 employees across Engineering, Sales, Marketing, Operations

## Query Reference

**Tree Traversal (`sql/02_tree_traversal/`)**
- `01_org_chart_full.sql` — full top-down org chart with reporting depth and a
  human-readable `reporting_chain` breadcrumb. Includes a cycle guard via an
  accumulated `id_path`, so a corrupted `manager_id` can't cause infinite recursion.
- `02_subordinates_of_manager.sql` — parameterized (`:manager_id`): every direct
  and indirect report under a given manager, with `relative_depth`.
- `03_management_chain_up.sql` — parameterized (`:employee_id`): walks upward
  from any employee to the CEO.

**Rollups (`sql/03_rollups/`)**
- `01_headcount_per_manager.sql` — direct + indirect report count for every
  manager, via an ancestor-walk recursive CTE.
- `02_salary_by_depth_level.sql` — employee count, total/avg/min/max salary
  aggregated by hierarchy depth (CEO → VP → Director → Manager → IC).
- `03_subtree_salary_rollup.sql` — fully-loaded compensation cost of each
  manager's entire downstream org (their own salary + every report, direct
  and indirect).
- `04_department_budget_variance.sql` — actual salary spend vs. allocated
  budget per department, with variance and an over/under-budget flag.

**Advanced (`sql/04_advanced/`)**
- `01_multiple_roots_handling.sql` — surfaces multiple root nodes (co-CEOs,
  disconnected records) and true data-quality orphans (a `manager_id` that
  points nowhere), so hierarchy corruption doesn't fail silently.
- `02_org_chart_at_depth.sql` — parameterized (`:target_depth`): returns just
  the employees at one hierarchy level.
- `03_salary_inversions.sql` — Part A finds the highest-paid person in each
  manager's entire subtree; Part B flags direct-report inversions (a report
  out-earning their own manager).
- `04_headcount_growth_over_time.sql` — cumulative headcount by hire year,
  org-wide and per department, using window functions over `hire_date`.
- `05_performance_notes.sql` — `EXPLAIN QUERY PLAN` output for the recursive
  traversal and department rollup, plus indexing rationale.

## Validation

| Check | Result |
|---|---|
| Row counts | 4 departments, 127 employees |
| Single root (CEO) | 1 |
| Orphan `manager_id` refs | 0 |
| Self-reference cycles | 0 |
| Reachability (no cycles, recursion terminates) | 127 / 127 |

## Key Findings (Day 3 Rollups)

- Total org-wide salary spend: **$14,260,621** (matches CEO's full subtree cost).
- 3 of 4 departments are currently **over budget**: Operations (+124% of
  budget), Marketing (+170%), and Sales (+17%). Engineering is under budget
  by $767,180.
- Headcount is heavily bottom-weighted: 94 of 127 employees (74%) sit at the
  deepest IC level (depth 5).

## Key Findings (Day 4 Advanced)

- **No salary inversions** exist between direct reports and their managers —
  a genuine data characteristic (level-based salary bands don't overlap),
  not a query bug.
- Org headcount grew steadily since 2015, reaching all 127 employees by 2025;
  the biggest single-year jump was 2018 (+21 hires).
- `EXPLAIN QUERY PLAN` confirms both indexes (`idx_employees_manager_id`,
  `idx_employees_department_id`) are already used by the query planner at
  this dataset's size — the recursive join and department rollup both hit
  index searches rather than full table scans.