CREATE TABLE departments (
    id INTEGER PRIMARY KEY,
    department VARCHAR(255)
);

CREATE TABLE jobs (
    id INTEGER PRIMARY KEY,
    job VARCHAR(255)
);

CREATE TABLE hired_employees (
    id INTEGER PRIMARY KEY,
    name VARCHAR(255),
    datetime TIMESTAMP,
    department_id INTEGER,
    job_id INTEGER,
    FOREIGN KEY (department_id) REFERENCES departments(id),
    FOREIGN KEY (job_id) REFERENCES jobs(id)
);

truncate TABLE hired_employees, departments, jobs;