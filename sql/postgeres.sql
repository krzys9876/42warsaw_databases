-- Let's check connectivity
select now();

-- What tables are there in our schema
select * from information_schema.tables where table_schema='public'

-- Cleanup before restart
drop table part cascade;
drop table project cascade;
drop table commit_part cascade;

-- Any questions about data types?
-- https://www.postgresql.org/docs/current/datatype.html

-- Create tables with no additional features
create table part (
    part_id int8, -- bigint, serial for autoincrement
    part_name varchar(20), -- text
    part_description varchar(100),
    quantity_on_hand numeric, -- decimal, decimal(10,4) etc.
    quantity_on_order numeric
);

create table project (
    project_id int8,
    project_name varchar(20),
    project_description varchar(100)
);

create table commit_part (
    part_id int8,
    project_id int8,
    quantity numeric
);

-- How do we insert data?
insert into part values (1, 'part1', 'part desc 1', 100, 20.5);
insert into part values (2, 'part2', 'part desc 2', 120, 10.2);

-- Show the entire table
select * from part;

-- Delete all rows (normally rarely used, rather you want to specify which rows to delete)
delete from part;

-- Explicitly clear the table
truncate table part;

-- Generate data in a loop
do $$
declare
    i int4;
begin
    for i in 1..10
    loop
        insert into part values (i, 'part' || i, 'part desc ' || i, i*10, i*2);
    end loop;
end
$$;


do $$
declare
    i int4;
begin
    for i in 1..3
    loop
        insert into project values (i, 'project' || i, 'project desc ' || i);
    end loop;
end
$$;

select * from project;

delete from project;

-- Note that we can have diplicates!
select round(random()*2)+1;

do $$
declare
    i int4;
begin
    for i in 1..20
    loop
        insert into commit_part values (round(random()*9)+1, round(random()*2)+1, round(random()*100)/2);
    end loop;
end
$$;

-- Can you spot the duplicates?
select * from commit_part
order by 1,2,3;

-- Better rely on code than just your eyes 
select part_id,project_id,count(*)
from commit_part
group by 1,2
having count(*)>1
order by 3 desc;

-- sometimes it is good to know if and how many duplicates we have
select cnt,count(*) from (
select part_id,project_id,count(*) as cnt
from commit_part
group by 1,2
) t
group by 1
order by 1;

-- Cleanup before data re-generation
delete from commit_part;

-- How do we actually write queries?
-- a single table
select part_id, project_id, quantity as qty from commit_part cp ;

-- join two tables by selected attribute(s)
select cp.part_id, p.part_name, p.part_description, cp.project_id, cp.quantity 
from commit_part cp 
join part p on p.part_id = cp.part_id ;

-- alternative syntax (discouraged)
select cp.part_id, p.part_name, p.part_description, cp.project_id, cp.quantity 
from commit_part cp, part p 
where p.part_id = cp.part_id ;

-- join more tables
select cp.part_id, p.part_name, p.part_description, cp.project_id, pr.project_name, pr.project_description, cp.quantity 
from commit_part cp 
join part p on p.part_id = cp.part_id 
join project pr on pr.project_id = cp.project_id
order by p.part_id, pr.project_id;

-- aggregate joined data
select cp.part_id,part_name,count(distinct cp.project_id) as project_cnt, sum(quantity) as quantity
from commit_part cp 
join part p on p.part_id = cp.part_id 
join project pr on pr.project_id = cp.project_id
group by cp.part_id,part_name
order by 1,2;

select cp.project_id,project_name,count(distinct cp.part_id) as part_cnt, sum(quantity) as quantity
from commit_part cp 
join part p on p.part_id = cp.part_id 
join project pr on pr.project_id = cp.project_id
group by cp.project_id,project_name
order by 1,2;

-- Let's simulate incomplete data
insert into commit_part (part_id, project_id, quantity) values (100,1000,5);

-- We should see empty part and project information
select cp.part_id, p.part_name, p.part_description, cp.project_id, pr.project_name, pr.project_description, cp.quantity 
from commit_part cp 
left join part p on p.part_id = cp.part_id 
left join project pr on pr.project_id = cp.project_id
order by p.part_id, pr.project_id;

-- Alternative syntax (discouraged) - left joins are not supported this way
select cp.part_id, p.part_name, p.part_description, cp.project_id, pr.project_name, pr.project_description, cp.quantity 
from commit_part cp , part p, project pr
where p.part_id = cp.part_id -- in Oracle you can left join by using (+): where p.part_id(+) = cp.part_id
and pr.project_id = cp.project_id
order by p.part_id, pr.project_id;


-- Constraints, data duplication and referential integrity
-- Duplicate entry
insert into part (part_id, part_name) values (1, 'part_1_duplicate')

select * from part;

delete from part where part_name='part_1_duplicate';

-- We can recreate the table (assuming we have source data to insert)
drop table part;

create table part (
    part_id int8 primary key, -- bigint, serial for autoincrement
    part_name varchar(20), -- text
    part_description varchar(100),
    quantity_on_hand numeric, -- decimal, decimal(10,4) etc.
    quantity_on_order numeric
);

-- Or we can add primary key to existing table
alter table part add primary key (part_id);

alter table project add primary key (project_id);

alter table commit_part add primary key (part_id, project_id);

truncate table commit_part;

do $$
declare
    i int4;
    part int8;
    project int8;
    commit_q numeric;
    exists_flg numeric;
begin
    for i in 1..20
    loop
        part:=round(random()*9)+1;
        project:=round(random()*2)+1;
        commit_q:=round(random()*100)/2;
        select count(*) into exists_flg from commit_part where project_id=project and part_id=part;
        if(exists_flg=0) then 
            insert into commit_part (part_id, project_id, quantity) values (part, project, commit_q);
        end if;
    end loop;
end
$$;

select * from commit_part;

select * from information_schema.table_constraints where table_schema='public';

select * from information_schema.constraint_column_usage where table_schema='public';

select * from information_schema.check_constraints where constraint_schema='public'

-- Let's fix commit_usage to match T. Codd guidelines
-- Drop existing primary key
alter table commit_part drop constraint commit_part_pkey;

-- Add proper primary key (autoincrement column)
-- We can drop the table...
drop table commit_part;

create table commit_part (
    id serial primary key,
    part_id int8, -- references part(part_id),
    project_id int8, -- references project(project_id),
    quantity numeric
);

-- or alter it
alter table commit_part add id serial;

alter table commit_part add primary key (id);

-- Add unique constraint to make sure there are no duplicates
alter table commit_part add constraint part_project_unique unique (part_id, project_id);

-- Add any arbitrary constraints
alter table commit_part add constraint low_quantity check (quantity<100);

alter table commit_part add constraint positive_quantity check (quantity>0);

-- Referential integrity - make sure all foreign IDs exist
-- Attempt to insert non-existing IDs
insert into commit_part (part_id, project_id, quantity) values (100,1000,5);

select * from commit_part;

delete from commit_part where part_id not in (select part_id from part);

alter table commit_part add constraint commit_part_part_id_fkey FOREIGN KEY (part_id) REFERENCES part(part_id);

alter table commit_part add constraint commit_part_project_id_fkey FOREIGN KEY (project_id) REFERENCES project(project_id);


------------------------------
-- Complex SQL queries
------------------------------
-- Quadratic equation
-- a*x^2 + b*x + c = 0

-- delta = b^2 - 4*a*c
-- two distinct roots (assuming delta is positive):
-- x1 = (-b + sqrt(delta))/(2*a)
-- x2 = (-b - sqrt(delta))/(2*a)

create table q_eq (id serial primary key, a numeric, b numeric, c numeric);

truncate table q_eq;

do $$
declare
    i int;
begin
    for i in 1..20
    loop
        insert into q_eq(a,b,c) values (round(random()*20)-10,round(random()*20)-10,round(random()*20)-10);
    end loop;
end
$$;

select * 
from q_eq
order by 1;

-- We cant reuse formulas in SQL!
select id, a, b, c, b*b-4*a*c as delta, case when delta>=0 then sqrt(delta) end as delta_sqrt
from q_eq
order by 1;

-- NOTE: you can do it in SAS, you can do it (programatically) in Apache Spark, but not in old good standard SQL
-- This requires rewriting queries in some form: CTE. select from (select from ...)) or creating views
-- CTE - Common Table Expressions
with q1 as (
select id, a, b, c, b*b-4*a*c as delta
from q_eq
), q2 as (
select id, a, b, c, delta, case when delta>=0 then sqrt(delta) else null end as delta_sqrt 
from q1
), q3 as (
select id, a, b, c, delta, delta_sqrt, 
case when delta_sqrt is not null and a!=0 then (-b-delta_sqrt)/(2*a) end as x1,
case when delta_sqrt is not null and a!=0 then (-b+delta_sqrt)/(2*a) end as x2
from q2
)
select * from q3;

-- Separate views approach
create view q_eq_delta as
select *, b*b-4*a*c as delta from q_eq;

create view q_eq_delta_sqrt as
select *, case when delta>=0 then sqrt(delta) else null end as delta_sqrt from q_eq_delta;

create view q_eq_res as
select *, 
case when delta_sqrt is not null and a!=0 then (-b-delta_sqrt)/(2*a) end as x1,
case when delta_sqrt is not null and a!=0 then (-b+delta_sqrt)/(2*a) end as x2
from q_eq_delta_sqrt;

select * from q_eq_res;

-- Select from (select from ...))
select q2.*, 
case when delta_sqrt is not null and a!=0 then (-b-delta_sqrt)/(2*a) end as x1,
case when delta_sqrt is not null and a!=0 then (-b+delta_sqrt)/(2*a) end as x2
from (
    select q1.*, case when delta>=0 then sqrt(delta) else null end as delta_sqrt 
    from (
        select *, b*b-4*a*c as delta from q_eq
    ) q1
) q2
order by 1;

-- Just repeat formula
select *, 
case when b*b-4*a*c>=0 and a!=0 then (-b-sqrt(b*b-4*a*c))/(2*a) end as x1,
case when b*b-4*a*c>=0 and a!=0 then (-b+dsqrt(b*b-4*a*c))/(2*a) end as x2
from q_eq;

-- Or maybe just use the relatively new SQL features (since 2013 Postgres and Oracle)?
select id,a,b,c,delta,delta_sqrt,x1,x2
from q_eq
cross join lateral (select b*b-4*a*c as delta) q1
cross join lateral (select case when delta>=0 then sqrt(delta) else null end as delta_sqrt) q2
cross join lateral (select 
case when delta_sqrt is not null and a!=0 then (-b-delta_sqrt)/(2*a) end as x1,
case when delta_sqrt is not null and a!=0 then (-b+delta_sqrt)/(2*a) end as x2
) q3
order by 1;

-- Use virtual columns
-- In postgres you can define calculated columns but they cannot reference one another (in SQL Server they can!)
create table q_eq_virtual (id serial primary key, a numeric, b numeric, c numeric, 
delta numeric generated always as (b*b-4*a*c) stored,
delta_sqrt numeric generated always as (case when delta>=0 then sqrt(delta) else null end) stored -- generates error
);

-- Another method is to define functions - although this may degrade performance
-- options: immuitable volatile (modifies database), stable (does not modify database, returns the same results for given arguments within single statement), immutable (does not modify database, returns same results for given arguments forever)
create or replace function delta_func(a numeric, b numeric, c numeric) returns numeric language plpgsql immutable 
as $$
begin
    return b*b-4*a*c;
end;
$$

create or replace function root_func(a numeric, b numeric, c numeric, root_no int) returns numeric language plpgsql immutable -- other options: volatile, stable
as $$
declare 
    delta numeric;
    delta_sqrt numeric;
begin
    delta:=delta_func(a, b, c);
    if delta>=0 and a!=0 then 
        delta_sqrt:=sqrt(delta);
        if root_no=1 then return -b-delta_sqrt/(2*a);
        else return -b+delta_sqrt/(2*a);
        end if;
    end if;
    return null;
end;
$$

select id,a,b,c,delta_func(a,b,c),root_func(a,b,c,1),root_func(a,b,c,2)
from q_eq


select version();

-----------------------------------------
select * from sb_part

truncate table sb_part cascade;

truncate table sb_project cascade;

truncate table sb_commit_part cascade;

do $$
declare
    i int4;
begin
    for i in 1..20
    loop
        insert into sb_part (id, name, description, quantity_on_hand, quantity_on_order) values (i,'part' || i, 'part desc ' || i, i*10, i*2);
    end loop;
end
$$;

select * from sb_part

do $$
declare
    i int4;
begin
    for i in 1..10
    loop
        insert into sb_project (id, name, description) values (i,'project' || i, 'project desc ' || i);
    end loop;
end
$$;

select * from sb_project;


do $$
declare
    i int4;
    part int8;
    project int8;
    commit_q numeric;
    exists_flg numeric;
begin
    for i in 1..100
    loop
        part:=round(random()*9)+1;
        project:=round(random()*2)+1;
        commit_q:=round(random()*100)/2;
        select count(*) into exists_flg from commit_part where project_id=project and part_id=part;
        if(exists_flg=0) then 
            insert into sb_commit_part (id, part_id, project_id, quantity) values (i, part, project, commit_q);
        end if;
    end loop;
end
$$;

select * from sb_commit_part;

select p1_0.name,count(distinct c1_0.project_id),coalesce(sum(c1_0.quantity),0) from sb_part p1_0 left join sb_commit_part c1_0 on c1_0.part_id=p1_0.id group by p1_0.id,p1_0.name order by p1_0.name

select p1_0.id,p1_0.description,p1_0.name,p1_0.quantity_on_hand,p1_0.quantity_on_order from sb_part p1_0

select c1_0.part_id,c1_0.id,p2_0.id,p2_0.description,p2_0.name,c1_0.project_id,c1_0.quantity from sb_commit_part c1_0 left join sb_project p2_0 on p2_0.id=c1_0.project_id where c1_0.part_id = any ('{1,2,3,4,5}')

select c1_0.part_id,c1_0.id,p2_0.id,p2_0.description,p2_0.name,c1_0.project_id,c1_0.quantity from sb_commit_part c1_0 left join sb_project p2_0 on p2_0.id=c1_0.project_id where c1_0.part_id = any ('{6,7,8,9,10}')

select c1_0.part_id,c1_0.id,p2_0.id,p2_0.description,p2_0.name,c1_0.project_id,c1_0.quantity from sb_commit_part c1_0 left join sb_project p2_0 on p2_0.id=c1_0.project_id where c1_0.part_id = any ('{11,12,13,14,15}')

select c1_0.part_id,c1_0.id,p2_0.id,p2_0.description,p2_0.name,c1_0.project_id,c1_0.quantity from sb_commit_part c1_0 left join sb_project p2_0 on p2_0.id=c1_0.project_id where c1_0.part_id = any ('{16,17,18,19,20}')