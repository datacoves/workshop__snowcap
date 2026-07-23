# databases.tf
#
# The analytics database and the fine-grained access-control role that grants
# USAGE on it. Mirrors resources/databases.yml.

resource "snowflake_database" "analytics" {
  name = "analytics"
}

resource "snowflake_account_role" "z_db__analytics" {
  name = "z_db__analytics"
}

resource "snowflake_grant_privileges_to_account_role" "z_db__analytics_usage" {
  account_role_name = snowflake_account_role.z_db__analytics.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.analytics.name
  }
}
