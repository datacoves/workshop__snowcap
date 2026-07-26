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

> 👉 **[Do the three branches produce the same result?](#do-the-three-branches-produce-the-same-result)**
> — a side-by-side of what each tool actually does, and where they diverge.

### The same warehouse, three ways

The clearest way to compare them is one object expressed in each syntax. Here is
the `wh_transforming` warehouse plus its matching `z_wh__<name>` access-control
role and grants — the same result in all three branches.

**Snowcap** — a `for_each` object template over a `vars` list
(`resources/object_templates/warehouse.yml`):

```yaml
warehouses:
  - for_each: var.warehouses
    name: "{{ each.value.name }}"
    warehouse_size: "{{ each.value.size }}"
    auto_suspend: "{{ each.value.auto_suspend }}"

roles:
  - for_each: var.warehouses
    name: "z_wh__{{ each.value.name }}"

grants:
  - for_each: var.warehouses
    priv: [USAGE, MONITOR]
    on: "warehouse {{ each.value.name }}"
    to: "z_wh__{{ each.value.name }}"
```

**Snowflake DCM** — declarative SQL. No loop here; the warehouse is written out
inline (`sources/definitions/warehouses.sql`):

```sql
DEFINE WAREHOUSE wh_transforming
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60;

DEFINE ROLE z_wh__wh_transforming;

GRANT USAGE, MONITOR ON WAREHOUSE wh_transforming TO ROLE z_wh__wh_transforming;
```

**Terraform** — HCL with `for_each` over a variable (`warehouses.tf`):

```hcl
resource "snowflake_warehouse" "this" {
  for_each       = var.warehouses
  name           = each.key
  warehouse_size = each.value.size
  auto_suspend   = each.value.auto_suspend
}

resource "snowflake_account_role" "z_wh" {
  for_each = var.warehouses
  name     = "z_wh__${each.key}"
}

resource "snowflake_grant_privileges_to_account_role" "z_wh_usage_monitor" {
  for_each          = var.warehouses
  account_role_name = snowflake_account_role.z_wh[each.key].name
  privileges        = ["USAGE", "MONITOR"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.this[each.key].name
  }
}
```

Snowcap and Terraform both keep the warehouse list in a variable, so adding one
is a single new entry. DCM supports Jinja loops too, but this workshop keeps it
inline for readability — note that DCM templates `.sql` files *before* parsing
them, so a Jinja tag written inside a `--` comment will fail the build.

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
- **`users.yml`** - Declares user `gomezn` and grants it `ACCOUNTADMIN`, `ANALYST`, and `REPORTER`

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
- A Snowflake account, and a role that can create **databases, schemas, warehouses, roles, users and grants**. `SECURITYADMIN` alone is *not* enough — it cannot create databases or warehouses:

  ```
  SQL access control error: Insufficient privileges to operate on account.
  Your primary role SECURITYADMIN must have CREATE DATABASE granted on ACCOUNT.
  ```

  Use `ACCOUNTADMIN`, or grant a purpose-built role what it needs (Snowcap's [permissions guide](https://snowcap.datacoves.com/snowflake-permissions/) walks through a least-privilege `SNOWCAP_ADMIN` role):

  ```sql
  GRANT CREATE DATABASE  ON ACCOUNT TO ROLE <your_role>;
  GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE <your_role>;
  GRANT CREATE ROLE      ON ACCOUNT TO ROLE <your_role>;
  GRANT CREATE USER      ON ACCOUNT TO ROLE <your_role>;
  GRANT MANAGE GRANTS    ON ACCOUNT TO ROLE <your_role>;
  ```
- `uv`/`uvx` installed (Snowcap is run via `uvx`, no separate install required)
- Key-pair authentication configured for your Snowflake user, with the public key registered on the **target** account (`ALTER USER <you> SET RSA_PUBLIC_KEY='...'`) — a key that works on one account is not automatically valid on another

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

<a name="orgadmin"></a>
### ⚠️ Don't add `ORGADMIN` unless you're on the primary account

This workshop deliberately does **not** grant `ORGADMIN`, and neither do the
other two branches. It's worth knowing why, because adding it is a natural thing
to try and the failure is confusing.

`ORGADMIN` exists only in an **organization's primary account**. In any other
account — including most trial and workshop accounts — the role simply isn't
there, so `./plan.sh` fails before it can plan anything:

```
Error fetching reference urn::<account>:role/ORGADMIN: Role "ORGADMIN" not found.
  Referenced by: role grant to user "GOMEZN"
```

Nothing in that message hints that `ORGADMIN` is special rather than misspelled.
Enabling it is an organization-level operation that has to be run manually, from
an account where the role already exists:

```sql
USE ROLE ORGADMIN;
ALTER ACCOUNT my_account SET IS_ORG_ADMIN = TRUE;
```

**No tool in this workshop can do that for you.** Snowcap has no resource for the
`IS_ORG_ADMIN` account property; DCM lists neither `ACCOUNT` nor `USER` among its
[supported entities](https://docs.snowflake.com/en/user-guide/dcm-projects/dcm-projects-supported-entities)
and its docs explicitly direct you to run `ALTER ACCOUNT` outside DCM. Terraform
is the only one that could, via
[`snowflake_account`](https://registry.terraform.io/providers/snowflakedb/snowflake/latest/docs/resources/account)
— but that resource manages *accounts*, not grants, and needs a provider session
already connected as `ORGADMIN`.

Note also that `ORGADMIN` can be enabled in at most **eight accounts** per
organization by default.

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

## Do the three branches produce the same result?

**Almost.** All three declare the same objects, and each one plans and runs
cleanly. What differs is not the object list but *how each tool decides what
already exists and who owns it*. Those differences are structural — they cannot
be configured away.

### What all three produce

Identical in every branch: the `analytics` database, its `staging` and `marts`
schemas, the `wh_transforming` warehouse, all eight roles (`analyst`, `reporter`
and the six `z_*` roles), the full role hierarchy and privilege grants, and
`gomezn` granted `ACCOUNTADMIN` + `ANALYST` + `REPORTER`.

### Where they genuinely differ

| | Snowcap (`main`) | DCM (`snowflake_dcm`) | Terraform (`terraform`) |
|---|---|---|---|
| **Detects existing objects** | Reads live Snowflake | Reads live Snowflake | ❌ **State file only** |
| **Manages `USER` objects** | ✅ creates them | ❌ **not supported** | ✅ creates them |
| **Object ownership** | Assigns defaults (`SYSADMIN` / `USERADMIN`) | Whoever deployed | Whoever applied |
| **Drop-on-remove** | Opt-in via `--sync_resources`; DB/schema excluded | **All** managed types, incl. DB/schema | Anything removed from `.tf` is destroyed |
| **Role switching mid-run** | Single role | Single role; `USE ROLE` rejected | Single role (aliases possible, unused here) |

`ORGADMIN` is not in this table because all three behave identically: none grant
it, so none of them differ in what they produce. It is a separate topic — see
[Don't add `ORGADMIN`](#orgadmin).

### The two that will surprise you

**1. Ownership churn if you run more than one tool against the same account.**
None of the three declare owners explicitly, but Snowcap applies *implicit
defaults* and will take ownership of objects another tool created. After
deploying the DCM branch (which leaves everything owned by the deploying role,
`SECURITYADMIN`), Snowcap plans **14 ownership transfers**:

```
» Plan: 3 to create, 1 to update, 14 to transfer, 0 to drop.
~ TRANSFER: ANALYTICS      owner: SECURITYADMIN → SYSADMIN
~ TRANSFER: WH_TRANSFORMING owner: SECURITYADMIN → SYSADMIN
...
```

Pick one tool per account, or the two will fight over ownership on every run.

**2. Terraform is blind to objects it did not create.** Its state file starts
empty, so against an account where the other branches have already deployed, it
plans to create everything again:

```
Plan: 34 to add, 0 to change, 0 to destroy.
```

Snowcap and DCM read live state and correctly report near-zero drift against the
same account. This is not a bug — it is the state-file model — but it means
Terraform needs either a **clean account** or `terraform import` to adopt
existing objects. Applying it over objects that already exist has not been
tested here and is not recommended.

### Smaller notes

- **`ANALYTICS.PUBLIC`** is auto-created with any database. Snowcap transfers its
  ownership, DCM created it, Terraform ignores it.
- **DCM requires `gomezn` to already exist.** It manages the role grants but
  cannot create the user, so a fresh account needs a one-off `CREATE USER` first.
- **DCM renders `.sql` files as Jinja templates before parsing**, including
  inside `--` comments — a Jinja tag in a comment fails the build.
- **DCM's deploying role needs the union of all privileges**, since `USE ROLE` is
  rejected in definition files. Transferring ownership away from that role breaks
  every subsequent run.

The `snowflake_dcm` and `terraform` branch READMEs document their own caveats in
more detail.

## Workshop Takeaways

- Snowflake infrastructure and access control can be declared and version-controlled the same way application code is
- Object templates + variables keep role/grant boilerplate DRY as new resources are added
- A layered role hierarchy (fine-grained `z_*` roles → functional roles) scales access control cleanly as teams grow
- `snowcap plan` makes infrastructure changes reviewable before they touch a live account
- Declarative tools differ in more than syntax: what they will drop, which object types they manage, and how many roles they can act as all shape how you use them — compare the `snowflake_dcm` and `terraform` branches to see the same design under three sets of constraints

---

*This repository serves as a reference implementation for the concepts covered in the Snowcap webinar. Feel free to explore the code and adapt it for your own use cases.*
