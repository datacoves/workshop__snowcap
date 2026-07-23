# warehouses.tf
#
# For each entry in var.warehouses, create the warehouse, a matching
# z_wh__<name> access-control role, and USAGE/MONITOR grants to that role.
# This for_each is the Terraform equivalent of Snowcap's
# resources/object_templates/warehouse.yml (driven by resources/warehouses.yml):
# adding a warehouse is just another entry in the var.warehouses map.

resource "snowflake_warehouse" "this" {
  for_each = var.warehouses

  name                = each.key
  warehouse_size      = each.value.size
  auto_suspend        = each.value.auto_suspend
  auto_resume         = true
  initially_suspended = true
}

resource "snowflake_account_role" "z_wh" {
  for_each = var.warehouses

  name = "z_wh__${each.key}"
}

resource "snowflake_grant_privileges_to_account_role" "z_wh_usage_monitor" {
  for_each = var.warehouses

  account_role_name = snowflake_account_role.z_wh[each.key].name
  privileges        = ["USAGE", "MONITOR"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.this[each.key].name
  }
}
