# schemas.tf
#
# The analytics.staging and analytics.marts schemas plus the fine-grained
# z_schemas__usage__* and z_tables_views__select__analytics roles/grants used to
# access them. Mirrors resources/schemas.yml.

resource "snowflake_schema" "staging" {
  database = snowflake_database.analytics.name
  name     = "staging"
}

resource "snowflake_schema" "marts" {
  database = snowflake_database.analytics.name
  name     = "marts"
}

resource "snowflake_account_role" "z_schemas__usage__staging" {
  name = "z_schemas__usage__staging"
}

resource "snowflake_account_role" "z_schemas__usage__marts" {
  name = "z_schemas__usage__marts"
}

resource "snowflake_account_role" "z_schemas__usage__all" {
  name = "z_schemas__usage__all"
}

resource "snowflake_account_role" "z_tables_views__select__analytics" {
  name = "z_tables_views__select__analytics"
}

# --- Per-schema USAGE ---------------------------------------------------------

resource "snowflake_grant_privileges_to_account_role" "usage_staging" {
  account_role_name = snowflake_account_role.z_schemas__usage__staging.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = snowflake_schema.staging.fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "usage_marts" {
  account_role_name = snowflake_account_role.z_schemas__usage__marts.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = snowflake_schema.marts.fully_qualified_name
  }
}

# --- USAGE on all + future schemas in the database ----------------------------

resource "snowflake_grant_privileges_to_account_role" "usage_all_schemas" {
  account_role_name = snowflake_account_role.z_schemas__usage__all.name
  privileges        = ["USAGE"]

  on_schema {
    all_schemas_in_database = snowflake_database.analytics.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "usage_future_schemas" {
  account_role_name = snowflake_account_role.z_schemas__usage__all.name
  privileges        = ["USAGE"]

  on_schema {
    future_schemas_in_database = snowflake_database.analytics.name
  }
}

# --- SELECT on all + future tables and views in the database ------------------

resource "snowflake_grant_privileges_to_account_role" "select_all_tables" {
  account_role_name = snowflake_account_role.z_tables_views__select__analytics.name
  privileges        = ["SELECT"]

  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_database        = snowflake_database.analytics.name
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "select_future_tables" {
  account_role_name = snowflake_account_role.z_tables_views__select__analytics.name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_database        = snowflake_database.analytics.name
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "select_all_views" {
  account_role_name = snowflake_account_role.z_tables_views__select__analytics.name
  privileges        = ["SELECT"]

  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.analytics.name
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "select_future_views" {
  account_role_name = snowflake_account_role.z_tables_views__select__analytics.name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_database        = snowflake_database.analytics.name
    }
  }
}
