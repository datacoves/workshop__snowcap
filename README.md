# webinar__snowcap

> **Hosted by [Datacoves](https://datacoves.com)** - Enterprise DataOps platform with managed dbt Core and Airflow for data transformation and orchestration.

This repository contains the materials and code examples from the **Snowcap** webinar held on **July 23, 2026**.

> 📚 Full documentation for Snowcap is available at [snowcap.datacoves.com](https://snowcap.datacoves.com).

## Overview

This workshop demonstrates how to manage Snowflake infrastructure as code using [Snowcap](https://github.com/datacoves/snowcap), a Snowflake-native, declarative provisioning tool. It walks through defining databases, warehouses, roles, users, schemas, and stages in YAML, then previewing and applying those definitions directly against a Snowflake account.

## Project Structure

### 📁 `/resources`
Contains the YAML resource definitions that make up the Snowcap configuration:
- **`databases.yml`** - Declares the `raw` and `analytics` databases
- **`warehouses.yml`** - Declares the `wh_transforming` warehouse (x-small, auto-suspend after 60s)
- **`schemas.yml`** - Declares schemas (e.g. `analytics.my_schema`, `raw.dbt_artifacts`) and their owners
- **`stages.yml`** - Declares an internal stage (`raw.dbt_artifacts.artifacts`) used to store dbt artifacts, plus read/write roles and grants
- **`users.yml`** - Declares users and their role grants
- **`roles__base.yml`** - Base-level roles and grants for schema/table access
- **`roles__functional.yml`** - Functional roles (e.g. `analyst`) and the role hierarchy that composes base roles into them

### 📁 `/resources/object_templates`
Reusable Snowcap templates that use `for_each` over variables to generate resources, roles, and grants consistently:
- **`database.yml`** - Creates a database, a matching `z_db__<name>` role, and a USAGE grant for each entry in `var.databases`
- **`warehouse.yml`** - Creates a warehouse, a matching `z_wh__<name>` role, and USAGE/MONITOR grants for each entry in `var.warehouses`
- **`schema.yml`** - Creates a schema, a matching `z_schema__<name>` role, and a USAGE grant for each entry in `var.schemas`
- **`user.yml`** - Creates a user (owned by `SECURITYADMIN`) for each entry in `var.users`

### 📁 Root Files
- **`plan.sh`** - Loads `.env` and runs `snowcap plan`, showing what would change without applying it
- **`apply.sh`** - Loads `.env` and runs `snowcap apply`, applying the resource definitions to the target Snowflake account
- **`.env.sample`** - Template for the environment variables required to connect to Snowflake

## Key Features Demonstrated

### 1. Snowflake Infrastructure as Code
- Declarative YAML definitions for databases, warehouses, schemas, stages, roles, users, and grants
- No state file to manage - Snowcap reads the current state directly from Snowflake
- `snowcap plan` to preview changes and `snowcap apply` to execute them

### 2. Reusable Templates with `for_each`
- Object templates iterate over list variables (`var.databases`, `var.warehouses`, `var.schemas`, `var.users`)
- Each template consistently generates the resource plus a matching access-control role and grant
- Adding a new database, warehouse, or schema is as simple as adding an entry to the relevant `vars` list

### 3. Role-Based Access Control Pattern
- Fine-grained `z_`-prefixed roles scoped to a single privilege/object (e.g. `z_wh__wh_transforming`, `z_tables_views__select__analytics`)
- Base roles (`roles__base.yml`) compose fine-grained grants
- Functional roles (`roles__functional.yml`) compose base roles into a role a human user is actually granted (e.g. `analyst`)


## Getting Started

### Prerequisites
- A Snowflake account with permissions to create databases, warehouses, roles, and users
- `uv`/`uvx` installed (Snowcap is run via `uvx`, no separate install required)
- A key-pair authentication key configured for your Snowflake user

### Setup Instructions

1. **Configure Environment**
   ```bash
   cp .env.sample .env
   # Fill in SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, SNOWFLAKE_ROLE, SNOWFLAKE_PRIVATE_KEY_PATH
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

1. **Basic Setup**: Defining databases, warehouses, and schemas in YAML and applying them for the first time
2. **Role Hierarchy**: Building fine-grained roles bottom-up into a functional role a user can be granted
3. **Templated Resources**: Using `for_each` object templates to add new databases/warehouses/schemas without duplicating boilerplate
4. **Plan vs Apply**: Comparing `snowcap plan` output against `snowcap apply` to understand exactly what changes before they happen

## Configuration Notes

- **Sync Resources**: `apply.sh` passes `--sync_resources role,grant,role_grant,warehouse,user,...` so Snowcap reconciles (and removes) resources no longer defined in YAML, not just adds new ones
- **Exclusions**: Enterprise-only resource types are excluded by default on the standard account to avoid errors on accounts without those features enabled
- **Templates**: All `object_templates/*.yml` files are driven by variables defined in the corresponding `resources/*.yml` file (e.g. `var.databases`, `var.warehouses`)

## Workshop Takeaways

- Snowflake infrastructure can be declared and version-controlled the same way application code is
- Object templates + variables keep role/grant boilerplate DRY as new resources are added
- A layered role hierarchy (fine-grained → base → functional) scales access control cleanly as teams grow
- `snowcap plan` makes infrastructure changes reviewable before they touch a live account

---

*This repository serves as a reference implementation for the concepts covered in the Snowcap webinar. Feel free to explore the code and adapt it for your own use cases.*
