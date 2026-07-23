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

# The Snowcap version also granted ACCOUNTADMIN and ORGADMIN to these users.
# Uncomment to match it exactly -- note the applying role must be allowed to
# grant them (ORGADMIN in particular can only be granted by ORGADMIN).
#
# resource "snowflake_grant_account_role" "user_accountadmin" {
#   for_each  = toset(var.users)
#   role_name = "ACCOUNTADMIN"
#   user_name = snowflake_user.this[each.value].name
# }
#
# resource "snowflake_grant_account_role" "user_orgadmin" {
#   for_each  = toset(var.users)
#   role_name = "ORGADMIN"
#   user_name = snowflake_user.this[each.value].name
# }
