-- Warehouse created outside of the DCM project (drift): the next ./deploy.sh
-- will NOT touch it, because DCM only manages objects it created.
use role sysadmin;
show warehouses;
create warehouse my_warehouse;
show warehouses;


-- What can Analyst see
use role analyst;
show tables in schema analytics.staging;
select * from analytics.staging.stg_some_table;

show tables in schema analytics.marts;
select * from analytics.marts.my_mart;

-- What can Reporter see
use role reporter;
show tables in schema analytics.staging;
select * from analytics.staging.stg_some_table;

show tables in schema analytics.marts;
select * from analytics.marts.my_mart;
