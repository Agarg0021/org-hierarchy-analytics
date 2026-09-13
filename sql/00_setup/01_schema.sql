-- ============================================================
-- Employee Hierarchy & Org Analytics — Day 1: Schema
-- Portable across PostgreSQL / MySQL 8+ / SQLite (WITH RECURSIVE support)
-- ============================================================

DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

CREATE TABLE departments (
    department_id   INTEGER PRIMARY KEY,
    department_name TEXT NOT NULL,
    budget          NUMERIC(12,2) NOT NULL
);

CREATE TABLE employees (
    employee_id   INTEGER PRIMARY KEY,
    name          TEXT NOT NULL,
    manager_id    INTEGER REFERENCES employees(employee_id),
    department_id INTEGER REFERENCES departments(department_id),
    job_title     TEXT NOT NULL,
    salary        NUMERIC(10,2) NOT NULL,
    hire_date     DATE NOT NULL
);

CREATE INDEX idx_employees_manager_id    ON employees(manager_id);
CREATE INDEX idx_employees_department_id ON employees(department_id);
