-- databases.sql
--
-- The analytics database and the fine-grained access-control role that grants
-- USAGE on it. Mirrors resources/databases.yml from the Snowcap version.

DEFINE DATABASE analytics;

DEFINE ROLE z_db__analytics;

GRANT USAGE ON DATABASE analytics TO ROLE z_db__analytics;
