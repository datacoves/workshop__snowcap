use role analyst;
show tables in schema analytics.staging;
select * from analytics.staging.stg_some_table;

show tables in schema analytics.marts;
select * from analytics.marts.my_mart;


use role reporter;
show tables in schema analytics.staging;
select * from analytics.staging.stg_some_table;

show tables in schema analytics.marts;
select * from analytics.marts.my_mart;
