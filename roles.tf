# roles.tf
#
# Functional roles (analyst, reporter) and the role hierarchy that composes the
# fine-grained z_* roles into each one. Mirrors resources/roles__functional.yml.
#
# analyst  -> USAGE on all schemas + SELECT on all tables/views
# reporter -> scoped to the marts schema only

resource "snowflake_account_role" "analyst" {
  name = "analyst"
}

resource "snowflake_account_role" "reporter" {
  name = "reporter"
}

# --- analyst role hierarchy ---------------------------------------------------

resource "snowflake_grant_account_role" "analyst_z_db" {
  role_name        = snowflake_account_role.z_db__analytics.name
  parent_role_name = snowflake_account_role.analyst.name
}

resource "snowflake_grant_account_role" "analyst_z_wh" {
  role_name        = snowflake_account_role.z_wh["wh_transforming"].name
  parent_role_name = snowflake_account_role.analyst.name
}

resource "snowflake_grant_account_role" "analyst_z_schemas_all" {
  role_name        = snowflake_account_role.z_schemas__usage__all.name
  parent_role_name = snowflake_account_role.analyst.name
}

resource "snowflake_grant_account_role" "analyst_z_select" {
  role_name        = snowflake_account_role.z_tables_views__select__analytics.name
  parent_role_name = snowflake_account_role.analyst.name
}

# --- reporter role hierarchy --------------------------------------------------

resource "snowflake_grant_account_role" "reporter_z_db" {
  role_name        = snowflake_account_role.z_db__analytics.name
  parent_role_name = snowflake_account_role.reporter.name
}

resource "snowflake_grant_account_role" "reporter_z_wh" {
  role_name        = snowflake_account_role.z_wh["wh_transforming"].name
  parent_role_name = snowflake_account_role.reporter.name
}

resource "snowflake_grant_account_role" "reporter_z_schemas_marts" {
  role_name        = snowflake_account_role.z_schemas__usage__marts.name
  parent_role_name = snowflake_account_role.reporter.name
}

resource "snowflake_grant_account_role" "reporter_z_select" {
  role_name        = snowflake_account_role.z_tables_views__select__analytics.name
  parent_role_name = snowflake_account_role.reporter.name
}
