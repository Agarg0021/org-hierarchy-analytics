import random
from datetime import date, timedelta

random.seed(42)

departments = [
    (1, "Engineering", 4_500_000),
    (2, "Sales", 2_800_000),
    (3, "Marketing", 1_200_000),
    (4, "Operations", 1_800_000),
]

first_names = ["James","Maria","Wei","Aisha","Liam","Priya","Carlos","Emma","Noah","Fatima",
               "Yuki","Olivia","Raj","Sofia","Ethan","Nina","Omar","Grace","Lucas","Zara",
               "Ivan","Chloe","Ahmed","Mei","Jack","Amara","Hiro","Elena","Sam","Layla"]
last_names = ["Smith","Chen","Patel","Garcia","Johnson","Khan","Silva","Muller","Kim","Nguyen",
              "Brown","Okafor","Rossi","Tanaka","Lopez","Ivanov","Cohen","Dubois","Park","Ali"]

def rand_name(used):
    while True:
        n = f"{random.choice(first_names)} {random.choice(last_names)}"
        if n not in used:
            used.add(n)
            return n

def rand_date(start_year=2015, end_year=2025):
    start = date(start_year, 1, 1)
    end = date(end_year, 12, 31)
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, delta))

used_names = set()
employees = []
eid = 1

# Level 1: CEO (manager_id = NULL), department = Operations (HQ)
ceo_id = eid
employees.append([eid, rand_name(used_names), None, 4, "Chief Executive Officer",
                   410000, rand_date(2015, 2016)])
eid += 1

# Level 2: VPs, one per department, report to CEO
vp_salary_range = (240000, 280000)
dept_vps = {}
for dept_id, dept_name, _ in departments:
    vid = eid
    dept_vps[dept_id] = vid
    title = f"VP of {dept_name}"
    employees.append([vid, rand_name(used_names), ceo_id, dept_id, title,
                       random.randint(*vp_salary_range), rand_date(2015, 2018)])
    eid += 1

# Level 3: Directors, 2 per VP
director_salary_range = (170000, 200000)
dept_directors = {d: [] for d in dept_vps}
for dept_id, vp_id in dept_vps.items():
    for i in range(2):
        did = eid
        dept_directors[dept_id].append(did)
        employees.append([did, rand_name(used_names), vp_id, dept_id, "Director",
                           random.randint(*director_salary_range), rand_date(2016, 2019)])
        eid += 1

# Level 4: Managers, 2-3 per director
manager_salary_range = (120000, 145000)
dept_managers = {d: [] for d in dept_vps}
for dept_id, directors in dept_directors.items():
    for did in directors:
        for i in range(random.randint(2, 3)):
            mid = eid
            dept_managers[dept_id].append(mid)
            employees.append([mid, rand_name(used_names), did, dept_id, "Manager",
                               random.randint(*manager_salary_range), rand_date(2017, 2021)])
            eid += 1

# Level 5: ICs, 3-6 per manager
ic_titles = {
    1: ["Software Engineer", "Senior Software Engineer", "QA Engineer", "DevOps Engineer"],
    2: ["Account Executive", "Sales Development Rep", "Sales Engineer"],
    3: ["Marketing Specialist", "Content Strategist", "SEO Analyst", "Brand Manager"],
    4: ["Operations Analyst", "Logistics Coordinator", "Office Manager"],
}
ic_salary_range = (70000, 115000)
for dept_id, managers in dept_managers.items():
    for mid in managers:
        for i in range(random.randint(3, 6)):
            icid = eid
            title = random.choice(ic_titles[dept_id])
            employees.append([icid, rand_name(used_names), mid, dept_id, title,
                               random.randint(*ic_salary_range), rand_date(2018, 2025)])
            eid += 1

# ---- Emit SQL ----
lines = []
lines.append("-- ============================================================")
lines.append("-- Employee Hierarchy & Org Analytics — Day 1: Seed Data")
lines.append(f"-- Generated: {len(departments)} departments, {len(employees)} employees, 5 levels deep")
lines.append("-- ============================================================\n")

lines.append("INSERT INTO departments (department_id, department_name, budget) VALUES")
dept_rows = [f"    ({d[0]}, '{d[1]}', {d[2]})" for d in departments]
lines.append(",\n".join(dept_rows) + ";\n")

lines.append("INSERT INTO employees (employee_id, name, manager_id, department_id, job_title, salary, hire_date) VALUES")
emp_rows = []
for e in employees:
    eid_, name, mgr, dept, title, salary, hdate = e
    mgr_sql = "NULL" if mgr is None else str(mgr)
    name_sql = name.replace("'", "''")
    title_sql = title.replace("'", "''")
    emp_rows.append(f"    ({eid_}, '{name_sql}', {mgr_sql}, {dept}, '{title_sql}', {salary}, '{hdate.isoformat()}')")
lines.append(",\n".join(emp_rows) + ";\n")

with open("/home/claude/org_project/02_seed.sql", "w") as f:
    f.write("\n".join(lines))

print(f"Generated {len(employees)} employees across {len(departments)} departments.")
print(f"CEO id: {ceo_id}")
