# users.tf
#
# Creates the human users and grants them the functional roles. Mirrors
# resources/users.yml. Unlike Snowflake DCM Projects (which can't manage USER
# objects), the Terraform provider CAN create users, so this is a 1:1 match with
# the Snowcap version -- snowflake_user is a PERSON-type user.

resource "snowflake_user" "this" {
  for_each = toset(var.users)

  name = each.value

  # Snowcap set default_secondary_roles: [] (i.e. none). Uncomment to enforce:
  # default_secondary_roles_option = "NONE"
}

resource "snowflake_grant_account_role" "user_analyst" {
  for_each = toset(var.users)

  role_name = snowflake_account_role.analyst.name
  user_name = snowflake_user.this[each.value].name
}

resource "snowflake_grant_account_role" "user_reporter" {
  for_each = toset(var.users)

  role_name = snowflake_account_role.reporter.name
  user_name = snowflake_user.this[each.value].name
}

# Matches the ACCOUNTADMIN grant in resources/users.yml. The applying role must
# itself be allowed to grant it.
resource "snowflake_grant_account_role" "user_accountadmin" {
  for_each = toset(var.users)

  role_name = "ACCOUNTADMIN"
  user_name = snowflake_user.this[each.value].name
}

# ORGADMIN is deliberately absent. It exists only in an organization's primary
# account, and no tool in this workshop can enable it there -- see the README.
# Terraform is the only one that could, via snowflake_account.is_org_admin, but
# that resource manages accounts rather than grants.
