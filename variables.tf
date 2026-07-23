# Connection variables. Defaults are read from the environment (TF_VAR_*),
# which plan.sh / apply.sh populate from your .env file.

variable "organization_name" {
  type        = string
  description = "Snowflake organization name (the part before '-' in the account identifier)."
}

variable "account_name" {
  type        = string
  description = "Snowflake account name (the part after '-' in the account identifier)."
}

variable "user" {
  type        = string
  description = "Snowflake user to authenticate as."
}

variable "role" {
  type        = string
  description = "Role used to apply changes. Needs to create databases, warehouses, roles and grants."
  default     = "ACCOUNTADMIN"
}

variable "private_key_path" {
  type        = string
  description = "Path to the PEM private key file for key-pair (JWT) authentication."
}

# Mirrors resources/warehouses.yml: the list of warehouses to create. Each entry
# also gets a matching z_wh__<name> access-control role and USAGE/MONITOR grant
# (see warehouses.tf), the Terraform equivalent of Snowcap's warehouse template.
variable "warehouses" {
  type = map(object({
    size         = string
    auto_suspend = number
  }))
  default = {
    wh_transforming = {
      size         = "XSMALL"
      auto_suspend = 60
    }
  }
}

# Mirrors the users declared in resources/users.yml. The functional roles
# analyst + reporter are granted to each (see users.tf).
variable "users" {
  type    = list(string)
  default = ["fmercado", "gomezn"]
}
