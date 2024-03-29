--������� 1

create schema skud

set search_path to skud


create table personal(
personal_id int primary key,
store_id int references store(store_id),
home_address_id int references address_personal(home_address_id),
last_name varchar(30),
first_name varchar(30)
)

create table address_personal(
home_address_id int primary key,
address varchar(100),
city_id int references city(city_id)
)

create table store(
store_id int primary key,
address varchar(100),
city_id int references city(city_id)
)

create table city(
city_id int primary key,
city varchar(30),
country varchar(50)
) 

create table timesheet(
job_date date,
personal_id int references personal(personal_id),
time_come_in_1 timestamp,
time_come_out_1 timestamp,
interval_1 interval, 			
time_come_in_2 timestamp,      
time_come_out_2 timestamp,
interval_2 interval,
constraint timesheet_pkey primary key (job_date, personal_id)
) 
-- �������� "��������" ������� ������������� ��� �������� ������ �� �������� 
-- (������� �� ���� �������� �������)


create table payroll (
personal_id int primary key references personal(personal_id),
pay_on_hour numeric, 
hours_at_month int, 
salary numeric
) 


-- �������������� �������

--��� ������������
create table skud_not_norm(
job_date date,
personal_id int,
last_name varchar(30),
first_name varchar(30),
home_address varchar(100), --�������� ����� ���������, � ��������� ������ (��������������)
store_id int,
store_address varchar(100), --����� �������, ��� �������� ��������, � ��������� ������ (��������������)
time_come_in timestamp[], -- ��� ����� ��������� �� ���� (������, ��������������)
time_come_out timestamp[], -- ��� ������ ��������� �� ���� (������, ��������������)
job_interval interval, -- ������� ���� �� ����
pay_on_hour numeric, -- ������ ���������� � ���
hours_at_month int, -- ���������� ������������ ����� � �����
salary numeric,
constraint pkey primary key (job_date, personal_id)
)

--1 ���������� �����
create table skud_1NF(
job_date date,
personal_id int,
last_name varchar(30),
first_name varchar(30),
home_address varchar(100),
personal_city_id int, 
store_id int,
store_address varchar(100),
store_city_id int, 
time_come_in_1 timestamp,
time_come_out_1 timestamp,
interval_1 interval,
time_come_in_2 timestamp,
time_come_out_2 timestamp, 
interval_2 interval,
pay_on_hour numeric,
hours_at_month int,
salary numeric,
constraint pkey_1NF primary key (job_date, personal_id)
)

--2 ���������� �����
create table skud_2NF_timesheet(  
job_date date, 					 
personal_id int,
time_come_in_1 timestamp,
time_come_out_1 timestamp,
interval_1 interval,
time_come_in_2 timestamp,
time_come_out_2 timestamp,
interval_2 interval,
constraint pkey_timesheet_2NF primary key (job_date, personal_id)
)

create table skud_2NF_payroll(
personal_id int primary key,
last_name varchar(30),
first_name varchar(30),
pay_on_hour numeric,
hours_at_month int,
salary numeric
)

create table skud_2NF_address(
personal_id int primary key, 
home_address varchar(100),
personal_city_id int, 
store_id int,
store_address varchar(100),
store_city_id int
)

--3 ���������� �����
create table skud_3NF_timesheet(
job_date date,
personal_id int,
time_come_in_1 timestamp,
time_come_out_1 timestamp,
interval_1 interval,
time_come_in_2 timestamp,
time_come_out_2 timestamp,
interval_2 interval,
constraint pkey_timesheet_3NF primary key (job_date, personal_id)
)

create table skud_3NF_address_personal(
personal_id int primary key, 
home_address varchar(100),
city_id int
)

create table skud_3NF_address_store(
store_id int primary key,
store_address varchar(100),
city_id int
)

create table skud_3NF_payroll(
personal_id int primary key,
last_name varchar(30),
first_name varchar(30),
pay_on_hour numeric,
hours_at_month int,
salary numeric
)

--���� - � ������� 1


--������� 2.1

create function timesheet_1() returns trigger as $$
 begin 
	  insert into timesheet(interval_1) values (new.time_come_out_1 - new.time_come_in_1);
	  end; $$
language plpgsql

 create trigger come_in_come_out_1
 after update on timesheet
 for each row 
 when (new.time_come_in_1 is not null
 	   and new.time_come_out_1 is not null
 	   and new.time_come_out_1 > new.time_come_in_1)
 execute function timesheet_1()
 
  
 create function timesheet_2() returns trigger as $$
 begin 
	  if timesheet.interval_1 is not null
	  then insert into timesheet(interval_2) values (new.time_come_out_2 - new.time_come_in_2);
	  end if;
	  end; $$
language plpgsql
 
 create trigger come_in_come_out_2
 after update on timesheet
 for each row 
 when (new.time_come_in_2 is not null
 	   and new.time_come_out_2 is not null
 	   and new.time_come_out_2 > new.time_come_in_2)
 execute function timesheet_2()
 
 
 --������� 2.2
 
 create view store_count_everyhour as
 (select * from
			(select now(), p.store_id, count(t.personal_id) over (partition by p.store_id)
			from timesheet t
			join personal p on p.personal_id = t.personal_id
			where (t.time_come_in_1 is not null and t.time_come_out_1 is null)
			or (t.time_come_in_2 is not null and t.time_come_out_2 is null)) t
 group by 2,3,1 -- ���������� ������� �� id �������, ����� ��� �� ��������� ��������
 order by 2) -- ��������� �� id �������
 
 select * from store_count_everyhour
 
 -- ��������� ������ ������ ������������������ �� ���������, �������, ������ �������������
 -- ������ �������, ���� �������� ���������� ����������. �������� ������ - ����� �����
 -- ������ ���� not null, � ����� ������ - null. 