-- warehouses.sql
--
-- The wh_transforming warehouse and its matching z_wh__<name> access-control
-- role, with USAGE + MONITOR granted to that role. Mirrors the templated
-- resources/object_templates/warehouse.yml (driven by resources/warehouses.yml)
-- from the Snowcap version.
--
-- Snowcap generated the warehouse, role and grant from a `for_each` over a
-- `warehouses` variable. DCM Projects support the same pattern with Jinja
-- (`{% for %}` + templating configs); here we keep the single warehouse inline
-- for clarity. To add another warehouse, copy the block below or wrap it in a
-- Jinja loop over a templating variable.

DEFINE WAREHOUSE wh_transforming
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

DEFINE ROLE z_wh__wh_transforming;

GRANT USAGE, MONITOR ON WAREHOUSE wh_transforming TO ROLE z_wh__wh_transforming;
