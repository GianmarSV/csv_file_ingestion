--List of ids, name and number of employees hired of each department that hired more
--employees than the mean of employees hired in 2021 for all the departments, ordered
--by the number of employees hired (descending).

with total_hired_by_department as (
select
  department_id,
  COUNT(1) total_hired
from hired_employees he
where EXTRACT('Year' FROM he.datetime)=2021
group by department_id
)
select
	d.id,
	d.department,
	the.total_hired as hired,
	mean
from (
select
	department_id,
	total_hired,
	AVG(total_hired) OVER() as mean
from total_hired_by_department
) the
left join departments d
  on the.department_id=d.id
where mean < total_hired
order by the.total_hired desc
