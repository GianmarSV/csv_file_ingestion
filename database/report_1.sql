--Number of employees hired for each job and department in 2021 divided by quarter. The
--table must be ordered alphabetically by department and job.

SELECT
    d.department,
    j.job,
    SUM(CASE WHEN EXTRACT(MONTH FROM he.datetime) BETWEEN 1 AND 3 THEN 1 ELSE 0 END) AS q1,
    SUM(CASE WHEN EXTRACT(MONTH FROM he.datetime) BETWEEN 4 AND 6 THEN 1 ELSE 0 END) AS q2,
    SUM(CASE WHEN EXTRACT(MONTH FROM he.datetime) BETWEEN 7 AND 9 THEN 1 ELSE 0 END) AS q3,
    SUM(CASE WHEN EXTRACT(MONTH FROM he.datetime) BETWEEN 10 AND 12 THEN 1 ELSE 0 END) AS q4
FROM
    hired_employees he 
    LEFT JOIN departments d
      ON he.department_id=d.id
    LEFT JOIN jobs j
      ON he.job_id=j.id
where EXTRACT('Year' FROM he.datetime)=2021
GROUP by d.department, j.job
order BY d.department ASC, j.job asc