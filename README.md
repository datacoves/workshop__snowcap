# Webinar - Snowcap

> **Hosted by [Datacoves](https://datacoves.com)** - Enterprise DataOps platform with managed dbt Core and Airflow for data transformation and orchestration.

This repository contains the materials and code examples from the **Snowcap** webinar held on **July 23, 2026**.

> 📚 Full documentation for Snowcap is available at [snowcap.datacoves.com](https://snowcap.datacoves.com).

## Overview

This workshop demonstrates how to manage Snowflake infrastructure as code using [Snowcap](https://github.com/datacoves/snowcap), a Snowflake-native, declarative provisioning tool. It walks through defining a warehouse in YAML, layering a fine-grained role hierarchy and user grants on top of a pre-existing database and schema, then previewing and applying those definitions directly against a Snowflake account.

## Project Structure

### 📁 `/resources`
Contains the YAML resource definitions that make up the Snowcap configuration:
- **`warehouses.yml`** - Declares the `wh_transforming` warehouse (x-small, auto-suspend after 60s)
- **`users.yml`** - Grants roles to users (e.g. `analyst` and `ACCOUNTADMIN` to `fmercado`)
- **`roles__base.yml`** - Base-level roles and grants for database/schema/table access on the existing `analytics` database
- **`roles__functional.yml`** - Functional roles (e.g. `analyst`) and the role hierarchy that composes base roles into them

### 📁 `/resources/object_templates`
Reusable Snowcap templates that use `for_each` over variables to generate resources, roles, and grants consistently:
- **`warehouse.yml`** - Creates a warehouse, a matching `z_wh__<name>` role, and USAGE/MONITOR grants for each entry in `var.warehouses`

### 📁 Root Files
- **`plan.sh`** - Loads `.env` and runs `snowcap plan`, showing what would change without applying it
- **`apply.sh`** - Loads `.env` and runs `snowcap apply`, applying the resource definitions to the target Snowflake account
- **`.env.sample`** - Template for the environment variables required to connect to Snowflake

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
- Fine-grained `z_`-prefixed roles scoped to a single privilege/object (e.g. `z_db__analytics`, `z_wh__wh_transforming`, `z_tables_views__select__analytics`)
- Base roles (`roles__base.yml`) define these fine-grained grants directly against the existing `analytics` database
- Functional roles (`roles__functional.yml`) compose base roles into a role a human user is actually granted (e.g. `analyst`)


## Getting Started

### Prerequisites
- A Snowflake account with permissions to create warehouses, roles, and users, plus an existing `analytics` database/schema to grant access to
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

1. **Basic Setup**: Defining a warehouse in YAML and layering access-control roles/grants on an existing database and schema
2. **Role Hierarchy**: Building fine-grained roles bottom-up into a functional role a user can be granted
3. **Templated Resources**: Using a `for_each` object template to add new warehouses without duplicating boilerplate
4. **Plan vs Apply**: Comparing `snowcap plan` output against `snowcap apply` to understand exactly what changes before they happen

## Configuration Notes

- **Sync Resources**: `apply.sh` passes `--sync_resources role,grant,role_grant,warehouse,user,...` so Snowcap reconciles (and removes) resources no longer defined in YAML, not just adds new ones
- **Exclusions**: Enterprise-only resource types are excluded by default on the standard account to avoid errors on accounts without those features enabled
- **Templates**: The `object_templates/warehouse.yml` template is driven by the `var.warehouses` variable defined in `resources/warehouses.yml`

## Workshop Takeaways

- Snowflake infrastructure and access control can be declared and version-controlled the same way application code is
- Object templates + variables keep role/grant boilerplate DRY as new resources are added
- A layered role hierarchy (fine-grained → base → functional) scales access control cleanly as teams grow
- `snowcap plan` makes infrastructure changes reviewable before they touch a live account

---

*This repository serves as a reference implementation for the concepts covered in the Snowcap webinar. Feel free to explore the code and adapt it for your own use cases.*
