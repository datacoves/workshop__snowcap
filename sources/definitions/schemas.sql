-- schemas.sql
--
-- The analytics.staging and analytics.marts schemas plus the fine-grained
-- z_schemas__usage__* and z_tables_views__select__analytics roles/grants used
-- to access them. Mirrors resources/schemas.yml from the Snowcap version.

DEFINE SCHEMA analytics.staging;
DEFINE SCHEMA analytics.marts;

DEFINE ROLE z_schemas__usage__staging;
DEFINE ROLE z_schemas__usage__marts;
DEFINE ROLE z_schemas__usage__all;
DEFINE ROLE z_tables_views__select__analytics;

-- Per-schema USAGE
GRANT USAGE ON SCHEMA analytics.staging TO ROLE z_schemas__usage__staging;
GRANT USAGE ON SCHEMA analytics.marts   TO ROLE z_schemas__usage__marts;

-- USAGE on every schema in the database, now and in the future
GRANT USAGE ON ALL SCHEMAS    IN DATABASE analytics TO ROLE z_schemas__usage__all;
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE analytics TO ROLE z_schemas__usage__all;

-- SELECT on every table and view in the database, now and in the future
GRANT SELECT ON ALL TABLES    IN DATABASE analytics TO ROLE z_tables_views__select__analytics;
GRANT SELECT ON ALL VIEWS     IN DATABASE analytics TO ROLE z_tables_views__select__analytics;
GRANT SELECT ON FUTURE TABLES IN DATABASE analytics TO ROLE z_tables_views__select__analytics;
GRANT SELECT ON FUTURE VIEWS  IN DATABASE analytics TO ROLE z_tables_views__select__analytics;
