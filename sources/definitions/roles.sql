-- roles.sql
--
-- Functional roles (analyst, reporter) and the role hierarchy that composes the
-- fine-grained z_* roles (defined alongside their databases, schemas and
-- warehouses) into each one. Mirrors resources/roles__functional.yml.
--
-- analyst  -> USAGE on all schemas + SELECT on all tables/views
-- reporter -> scoped to the marts schema only

DEFINE ROLE analyst;
DEFINE ROLE reporter;

-- analyst role hierarchy
GRANT ROLE z_db__analytics                    TO ROLE analyst;
GRANT ROLE z_wh__wh_transforming              TO ROLE analyst;
GRANT ROLE z_schemas__usage__all              TO ROLE analyst;
GRANT ROLE z_tables_views__select__analytics  TO ROLE analyst;

-- reporter role hierarchy
GRANT ROLE z_db__analytics                    TO ROLE reporter;
GRANT ROLE z_wh__wh_transforming              TO ROLE reporter;
GRANT ROLE z_schemas__usage__marts            TO ROLE reporter;
GRANT ROLE z_tables_views__select__analytics  TO ROLE reporter;
