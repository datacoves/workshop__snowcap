terraform {
  required_version = ">= 1.5"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.0"
    }
  }
}

# Connection values come from variables so the same .env used by the Snowcap
# version drives Terraform too: plan.sh / apply.sh translate SNOWFLAKE_* into
# the TF_VAR_* below (splitting SNOWFLAKE_ACCOUNT into org + account).
provider "snowflake" {
  organization_name = var.organization_name
  account_name      = var.account_name
  user              = var.user
  role              = var.role
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = file(var.private_key_path)
}
