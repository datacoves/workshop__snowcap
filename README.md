# Webinar - Snowcap

> **Hosted by [Datacoves](https://datacoves.com)** - Enterprise DataOps platform with managed dbt Core and Airflow for data transformation and orchestration.

This repository contains the materials and code examples from the Datacove **Snowcap** webinar held on **July 23, 2026**.

> 📚 Full documentation for Snowcap is available at [snowcap.datacoves.com](https://snowcap.datacoves.com).

## Three implementations, one workshop

The **same** database, schemas, warehouse, role hierarchy and grants are built
three ways, one per branch. Only the tool that declares and applies them
changes, so you can compare them side by side:

| Branch | Tool | Definitions | State model |
|---|---|---|---|
| **`main`** (this one) | [Snowcap](https://snowcap.datacoves.com) | YAML (`resources/*.yml`) | Reads live Snowflake state |
| **[`snowflake_dcm`](../../tree/snowflake_dcm)** | [Snowflake DCM Projects](https://docs.snowflake.com/en/user-guide/dcm-projects/dcm-projects-overview) | SQL `DEFINE` + `GRANT` (`sources/definitions/*.sql`) | Reads live Snowflake state |
| **[`terraform`](../../tree/terraform)** | [Terraform](https://developer.hashicorp.com/terraform) + `snowflakedb/snowflake` | HCL (`*.tf`) | State file |

All three read the same `.env` connection variables, so you can switch branches
and re-run without reconfiguring.

## Overview

This workshop demonstrates how to manage Snowflake infrastructure as code using **Snowcap**, a Snowflake-native, declarative provisioning
tool. It walks through defining a database, schemas, and a warehouse in YAML, layering a fine-grained role hierarchy and user grants on top
of them, then previewing and applying those definitions directly against a Snowflake account.

## Project Structure

### 📁 `/resources`
Contains the YAML resource definitions that make up the Snowcap configuration:
- **`warehouses.yml`** - Declares the `warehouses` list variable used by the warehouse object template (currently `wh_transforming`, x-small, auto-suspend after 60s)
- **`databases.yml`** - Declares the `analytics` database, the `z_db__analytics` role, and its USAGE grant
- **`schemas.yml`** - Declares the `analytics.staging` and `analytics.marts` schemas plus the fine-grained `z_schemas__usage__*`
and `z_tables_views__select__analytics` roles/grants for accessing them
- **`roles__functional.yml`** - Functional roles (`analyst`, `reporter`) and the role hierarchy that composes the fine-grained `z_*` roles into each one
- **`users.yml`** - Declares users `fmercado` and `gomezn` and grants them `ACCOUNTADMIN`, `ORGADMIN`, `ANALYST`, and `REPORTER`

### 📁 `/resources/object_templates`
Reusable Snowcap templates that use `for_each` over variables to generate resources, roles, and grants consistently:
- **`warehouse.yml`** - Creates a warehouse, a matching `z_wh__<name>` role, and USAGE/MONITOR grants for each entry in `var.warehouses`

### 📁 Root Files
- **`plan.sh`** - Loads `.env` and runs `snowcap plan`, showing what would change without applying it
- **`apply.sh`** - Loads `.env` and runs `snowcap apply`, applying the resource definitions to the target Snowflake account
- **`.env.sample`** - Template for the environment variables required to connect to Snowflake
- **`snowcap_test.sql`** - Sample worksheet for verifying access: switches to the `analyst` and `reporter` roles and queries the
`analytics.staging`/`analytics.marts` schemas to confirm the granted access works as expected

## Key Features Demonstrated

### 1. Snowflake Infrastructure as Code
- Declarative YAML definitions for warehouses, roles, users, and grants
- No state file to manage - Snowcap reads the current state directly from Snowflake
- `snowcap plan` to preview changes and `snowcap apply` to execute them

### 2. Reusable Templates with `for_each`
- The warehouse object template iterates over the `var.warehouses` list variable
- It consistently generates the warehouse plus a matching `z_wh__<name>` access-control role and grant
- Adding a new warehouse is as simple as adding an entry to the `warehouses` vars list

### 3. Role-Based Access Control Pattern
- Fine-grained `z_`-prefixed roles scoped to a single privilege/object (e.g. `z_db__analytics`, `z_wh__wh_transforming`,
`z_schemas__usage__marts`, `z_tables_views__select__analytics`)
- These fine-grained roles and their grants are defined alongside the resources they protect (`databases.yml`, `schemas.yml`,
`object_templates/warehouse.yml`)
- Functional roles (`roles__functional.yml`) compose the fine-grained roles into roles a human user is actually granted
(`analyst`, `reporter`) - `analyst` gets usage on all schemas, `reporter` is scoped to just `marts`


## Getting Started

### Prerequisites
- A Snowflake account with permissions to create databases, schemas, warehouses, roles, and users (e.g. `SECURITYADMIN`)
- `uv`/`uvx` installed (Snowcap is run via `uvx`, no separate install required)
- A key-pair authentication key configured for your Snowflake user

### Setup Instructions

1. **Configure Environment**
   ```bash
   cp .env.sample .env
   # Fill in SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, SNOWFLAKE_ROLE, SNOWFLAKE_PRIVATE_KEY_PATH
   # (SNOWFLAKE_ACCOUNT_PII and SNOWFLAKE_PASSWORD are optional/unused with key-pair auth)
   ```

2. **Preview Changes**
   ```bash
   ./plan.sh
   ```

3. **Apply Changes**
   ```bash
   ./apply.sh
   ```

## Workshop Scenarios

The workshop walks through several scenarios:

1. **Basic Setup**: Defining a database, its schemas, and a warehouse in YAML, alongside the fine-grained access-control roles/grants for each
2. **Role Hierarchy**: Building fine-grained (`z_*`) roles bottom-up into functional roles (`analyst`, `reporter`) that users are actually granted
3. **Templated Resources**: Using a `for_each` object template to add new warehouses without duplicating boilerplate
4. **Plan vs Apply**: Comparing `snowcap plan` output against `snowcap apply` to understand exactly what changes before they happen
5. **Verifying Access**: Using `snowcap_test.sql` to confirm the `analyst` and `reporter` roles can actually query the schemas they were granted

## Configuration Notes

- **Sync Resources**: `plan.sh`/`apply.sh` pass `--sync_resources role,grant,role_grant,warehouse,user` so Snowcap reconciles (and removes) resources of those types no longer defined in YAML, not just adds new ones
- **Unsynced Types**: `database` and `schema` are intentionally left out of `--sync_resources`, so Snowcap will create/update them but won't drop a database or schema just because it's removed from YAML
- **Templates**: The `object_templates/warehouse.yml` template is driven by the `var.warehouses` variable defined in `resources/warehouses.yml`

## Known Issues & Caveats

### ⚠️ `ORGADMIN` is not present in most accounts

`resources/users.yml` grants `ORGADMIN` to both users. That role only exists in
an **organization's primary account**, so in a normal account (including most
trial and workshop accounts) `./plan.sh` fails before it can plan anything:

```
Error fetching reference urn::<account>:role/ORGADMIN: Role "ORGADMIN" not found.
  Referenced by: role grant to user "FMERCADO"
```

Remove `ORGADMIN` from both `role_grants` entries in `resources/users.yml`
unless you are deploying to the primary account. The same caveat applies to the
`snowflake_dcm` branch, where those grants are commented out by default.

### ⚠️ Key-pair auth is per-account

A private key that authenticates against one Snowflake account is **not**
automatically valid against another — the public key has to be registered on
each. Pointing `.env` at a new account without doing so gives a misleading
error that looks like a bad key rather than a missing registration:

```
250001 (08001): Failed to connect to DB: <account>.snowflakecomputing.com:443.
JWT token is invalid.
```

Register it with `ALTER USER <you> SET RSA_PUBLIC_KEY='<base64>'`, then confirm
the fingerprint matches `DESC USER <you>`:

```bash
openssl rsa -in <key>.pem -pubout -outform DER \
  | openssl dgst -sha256 -binary | openssl enc -base64
```

### Tool-specific caveats

Worth knowing before you pick one for real work:

| | Caveat |
|---|---|
| **Snowcap** (`main`) | Drop-on-remove is opt-in per type via `--sync_resources`; `database` and `schema` are deliberately excluded here so they are never dropped |
| **DCM** (`snowflake_dcm`) | Reconciles **all** managed types including databases and schemas — removing a definition drops the object, so always `plan` first |
| **DCM** (`snowflake_dcm`) | Cannot manage `USER` objects at all; users must already exist and only their role grants are declarative |
| **DCM** (`snowflake_dcm`) | Runs the whole deployment as a **single role** — `USE ROLE` is rejected, so the deploying role needs the union of all privileges. Transferring ownership away from it breaks every subsequent run |
| **DCM** (`snowflake_dcm`) | Renders `.sql` files as Jinja templates *before* parsing, including inside `--` comments |
| **Terraform** (`terraform`) | Keeps a **state file**; unlike the other two it diffs against that rather than live Snowflake, so out-of-band changes cause drift |

The `snowflake_dcm` branch README documents its caveats in detail, including the
ownership-transfer failure and its recovery path.

## Workshop Takeaways

- Snowflake infrastructure and access control can be declared and version-controlled the same way application code is
- Object templates + variables keep role/grant boilerplate DRY as new resources are added
- A layered role hierarchy (fine-grained `z_*` roles → functional roles) scales access control cleanly as teams grow
- `snowcap plan` makes infrastructure changes reviewable before they touch a live account
- Declarative tools differ in more than syntax: what they will drop, which object types they manage, and how many roles they can act as all shape how you use them — compare the `snowflake_dcm` and `terraform` branches to see the same design under three sets of constraints

---

*This repository serves as a reference implementation for the concepts covered in the Snowcap webinar. Feel free to explore the code and adapt it for your own use cases.*
