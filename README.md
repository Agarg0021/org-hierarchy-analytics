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

## Validation

| Check | Result |
|---|---|
| Row counts | 4 departments, 127 employees |
| Single root (CEO) | 1 |
| Orphan `manager_id` refs | 0 |
| Self-reference cycles | 0 |
| Reachability (no cycles, recursion terminates) | 127 / 127 |