# Webinar - Snowcap (Terraform edition)

> **Hosted by [Datacoves](https://datacoves.com)** - Enterprise DataOps platform with managed dbt Core and Airflow for data transformation and orchestration.

This branch reimplements the [Snowcap](https://snowcap.datacoves.com) workshop
using **[Terraform](https://developer.hashicorp.com/terraform)** and the
official **[`snowflakedb/snowflake`](https://registry.terraform.io/providers/snowflakedb/snowflake/latest)**
provider instead of Snowcap. The **same** database, schemas, warehouse, role
hierarchy, users and grants are defined; only the tool that declares and applies
them changes.

> 📚 The `main` branch contains the original Snowcap implementation. Compare the
> two to see how the same infrastructure-as-code is expressed in each tool.

## Overview

Like Snowcap, Terraform lets you declare the **desired state** of Snowflake
objects and let the tool compute the changes needed to reach it. Instead of
Snowcap's YAML, Terraform uses HCL (`.tf`) resources; instead of reading live
state on every run, Terraform records what it manages in a **state file** and
diffs against that.

You describe a database, its schemas and a warehouse, layer a fine-grained role
hierarchy and user grants on top, then **plan** and **apply** those definitions
directly against a Snowflake account.

## Project Structure

Terraform loads every `.tf` file in this directory and resolves dependencies
between resources automatically, so file organization is just for humans. Grants
are co-located with the objects they protect, mirroring the Snowcap layout.

- **`providers.tf`** — Terraform + `snowflakedb/snowflake` provider version and connection config
- **`variables.tf`** — connection variables plus the `warehouses` and `users` inputs
- **`databases.tf`** — the `analytics` database, the `z_db__analytics` role and its USAGE grant (mirrors `databases.yml`)
- **`schemas.tf`** — the `staging`/`marts` schemas plus the `z_schemas__usage__*` and `z_tables_views__select__analytics` roles/grants, including `ALL` + `FUTURE` grants (mirrors `schemas.yml`)
- **`warehouses.tf`** — a `for_each` over `var.warehouses` that creates each warehouse, its `z_wh__<name>` role and USAGE/MONITOR grant (mirrors the `object_templates/warehouse.yml` template)
- **`roles.tf`** — the functional roles (`analyst`, `reporter`) and the role hierarchy (mirrors `roles__functional.yml`)
- **`users.tf`** — creates users `fmercado`/`gomezn` and grants them the functional roles (mirrors `users.yml`)

### Root Files
- **`plan.sh`** — loads `.env`, maps it to `TF_VAR_*`, runs `terraform init` + `terraform plan` (equivalent to `snowcap plan`)
- **`apply.sh`** — same, then `terraform apply` (equivalent to `snowcap apply`)
- **`.env.sample`** — template for the Snowflake connection variables
- **`terraform.tfvars.example`** — optional overrides (extra warehouses/users, or inline connection)
- **`snowflake_test.sql`** — worksheet for verifying access: switches to `analyst`/`reporter` and queries the `analytics` schemas

## How to Run It

### Prerequisites
- **Terraform** ≥ 1.5 installed ([download](https://developer.hashicorp.com/terraform/install))
- A Snowflake account and a role able to create databases, schemas, warehouses, roles, users and grants (**`ACCOUNTADMIN`** is simplest)
- Key-pair (JWT) authentication configured for your Snowflake user

### 1. Configure the connection
```bash
cp .env.sample .env
# Fill in SNOWFLAKE_ACCOUNT (as ORG-ACCOUNT), SNOWFLAKE_USER,
# SNOWFLAKE_ROLE, SNOWFLAKE_PRIVATE_KEY_PATH
```
`plan.sh`/`apply.sh` read `.env` and export the matching `TF_VAR_*` values
(splitting `SNOWFLAKE_ACCOUNT` into the provider's `organization_name` +
`account_name`), so the same `.env` used by the Snowcap version works here.

### 2. Preview changes
```bash
./plan.sh
```
Runs `terraform init` (first time downloads the provider) then `terraform plan`
— shows every resource that would be created, changed or destroyed. Nothing is
applied.

### 3. Apply changes
```bash
./apply.sh
# or skip the interactive approval:
./apply.sh -auto-approve
```

### 4. Verify access
Open `snowflake_test.sql` in a Snowflake worksheet and step through it to confirm
the `analyst` and `reporter` roles can query the schemas they were granted.

> **State:** Terraform writes a `terraform.tfstate` file recording what it
> manages. It is git-ignored here (it can contain sensitive values). For real,
> shared use, configure a [remote backend](https://developer.hashicorp.com/terraform/language/backend)
> so state is stored centrally and locked.

## Key Features Demonstrated

### 1. Snowflake Infrastructure as Code
- Declarative HCL resources for databases, schemas, warehouses, roles, users and grants
- `terraform plan` to preview and `terraform apply` to execute
- A dependency graph Terraform derives automatically from resource references

### 2. Reusable definitions with `for_each`
- `warehouses.tf` iterates over `var.warehouses` to generate each warehouse plus a matching `z_wh__<name>` role and grant — the Terraform equivalent of Snowcap's warehouse template. Adding a warehouse is one more map entry.

### 3. Role-Based Access Control Pattern
- Fine-grained `z_`-prefixed roles scoped to a single privilege/object (`z_db__analytics`, `z_wh__wh_transforming`, `z_schemas__usage__marts`, `z_tables_views__select__analytics`), each co-located with the object it protects
- Functional roles (`analyst`, `reporter`) compose those into roles users are actually granted — `analyst` gets usage on all schemas, `reporter` is scoped to just `marts`

## Difference from Snowcap

| | Snowcap (`main`) | Terraform (this branch) |
|---|---|---|
| Definition format | YAML (`resources/*.yml`) | HCL (`*.tf`) |
| Runner | `uvx snowcap plan/apply` | `terraform plan/apply` |
| State | Reads live Snowflake state each run | Records managed objects in a **state file** |
| Templating / DRY | `for_each` over `vars` | `for_each` over variables |
| Manages USER objects | ✅ | ✅ (`snowflake_user`) |
| Drop-on-remove | Opt-in per type via `--sync_resources` (DB/schema excluded) | Anything removed from `.tf` is destroyed on the next apply — always review `./plan.sh` first |

### Notes
- **State drift:** because Terraform tracks state, an object it created and then
  removed from the config is **destroyed** on the next apply (see the destroy
  count in `plan`). Snowcap instead reconciles against live Snowflake and only
  drops the types listed in `--sync_resources` (never databases/schemas). Review
  the plan before applying.
- **Grant model:** each `snowflake_grant_privileges_to_account_role` /
  `snowflake_grant_account_role` resource is one grant, so the single Snowcap
  grant blocks that spanned `all`/`future` tables and views expand into a few
  explicit resources here.
- **Users** are created with `snowflake_user` (PERSON type). The `ACCOUNTADMIN`
  /`ORGADMIN` grants from `users.yml` are included as commented resources in
  `users.tf` — enable them if your applying role is allowed to grant them.

## Workshop Takeaways

- Snowflake infrastructure and access control can be declared and version-controlled the same way application code is
- `for_each` over variables keeps role/grant boilerplate DRY as new resources are added
- A layered role hierarchy (fine-grained `z_*` roles → functional roles) scales access control cleanly as teams grow
- `terraform plan` makes infrastructure changes reviewable before they touch a live account — and its state file is both its superpower (fast diffs, drift detection) and the thing to manage carefully (secrets, locking, remote backends)

---

*This branch is a reference implementation of the Snowcap webinar concepts using Terraform. Explore it alongside `main` and adapt for your own use cases.*
