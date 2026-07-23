# Webinar - Snowcap (Snowflake DCM edition)

> **Hosted by [Datacoves](https://datacoves.com)** - Enterprise DataOps platform with managed dbt Core and Airflow for data transformation and orchestration.

This branch reimplements the [Snowcap](https://snowcap.datacoves.com) workshop
using **[Snowflake DCM Projects](https://docs.snowflake.com/en/user-guide/dcm-projects/dcm-projects-overview)**
(Declarative Change Management) — Snowflake's own native, declarative
object-management feature — instead of Snowcap. The **same** database, schemas,
warehouse, role hierarchy and grants are defined; only the tool that declares
and applies them changes.

> 📚 The `main` branch contains the original Snowcap implementation. Compare the
> two to see how the same infrastructure-as-code is expressed in each tool.

## Overview

Like Snowcap, DCM Projects let you declare the **desired state** of Snowflake
objects and let the tool figure out the `CREATE` / `ALTER` / `DROP` needed to
get there. Instead of Snowcap's YAML, DCM uses SQL definition files built from
`DEFINE` statements plus ordinary `GRANT`s, organized under a `manifest.yml`.

You describe a database, its schemas and a warehouse, layer a fine-grained role
hierarchy and user grants on top, then **plan** and **deploy** those definitions
directly against a Snowflake account with the Snowflake CLI (`snow dcm`).

## Project Structure

### 📁 `sources/definitions`
The declarative SQL definition files. DCM auto-discovers every `.sql` file here
and resolves dependencies between objects across files, so ordering doesn't
matter.

- **`databases.sql`** — the `analytics` database, the `z_db__analytics` role and its USAGE grant
- **`schemas.sql`** — the `analytics.staging` and `analytics.marts` schemas plus the fine-grained `z_schemas__usage__*` and `z_tables_views__select__analytics` roles/grants (including `ALL` + `FUTURE` grants)
- **`warehouses.sql`** — the `wh_transforming` warehouse, its matching `z_wh__wh_transforming` role, and USAGE/MONITOR grants
- **`roles.sql`** — the functional roles (`analyst`, `reporter`) and the role hierarchy that composes the `z_*` roles into each one
- **`users.sql`** — grants `analyst`/`reporter` to the human users (`fmercado`, `gomezn`)

### 📁 Root Files
- **`manifest.yml`** — the DCM project manifest (`manifest_version` + `type: DCM_PROJECT`)
- **`_env.sh`** — shared helper: loads `.env`, validates it, and builds the `snow` connection flags
- **`setup.sh`** — one-time bootstrap: creates the home DB/schema for the project object and runs `snow dcm create`
- **`plan.sh`** — runs `snow dcm plan` (preview, the DCM equivalent of `snowcap plan`)
- **`deploy.sh`** — runs `snow dcm deploy` (apply, the DCM equivalent of `snowcap apply`)
- **`.env.sample`** — template for the Snowflake connection variables
- **`dcm_test.sql`** — worksheet for verifying access: switches to `analyst`/`reporter` and queries the `analytics` schemas

## How to Run It

### Prerequisites
- A Snowflake account and a role able to create databases, schemas, warehouses, roles and grants (**`ACCOUNTADMIN`** is simplest; see the note in `.env.sample` for a least-privilege alternative)
- `uv`/`uvx` installed — the Snowflake CLI is run via `uvx --from snowflake-cli snow`, so **no separate install is required**
- Key-pair (JWT) authentication configured for your Snowflake user
- The users referenced in `sources/definitions/users.sql` (`fmercado`, `gomezn`) must already exist — see [Difference from Snowcap](#difference-from-snowcap-users)

### 1. Configure the connection
```bash
cp .env.sample .env
# Fill in SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, SNOWFLAKE_ROLE, SNOWFLAKE_PRIVATE_KEY_PATH
```
The scripts read `.env` and pass a **temporary connection** to `snow` (via `-x`
and `--account/--user/...` flags), so you do **not** need a `connections.toml`.

### 2. Bootstrap the project (once)
A DCM Project is itself a Snowflake object that lives in a schema, so this
creates a small home database/schema (`dcm.projects` by default, set via
`DCM_PROJECT` in `.env`) and the empty project object:
```bash
./setup.sh
```

### 3. Preview changes
```bash
./plan.sh
```
Shows every object that would be created, altered or dropped — nothing is
changed.

### 4. Apply changes
```bash
./deploy.sh
# optionally label the deployment:
./deploy.sh --alias "workshop baseline"
```

### 5. Verify access
Open `dcm_test.sql` in a Snowflake worksheet and step through it to confirm the
`analyst` and `reporter` roles can query the schemas they were granted.

## Key Features Demonstrated

### 1. Snowflake Infrastructure as Code, natively
- Declarative SQL (`DEFINE ...`) for databases, schemas, warehouses, roles and grants
- No state file to manage — DCM reads current state directly from Snowflake and diffs against your definitions
- `snow dcm plan` to preview and `snow dcm deploy` to apply

### 2. Role-Based Access Control Pattern
- Fine-grained `z_`-prefixed roles scoped to a single privilege/object (e.g. `z_db__analytics`, `z_wh__wh_transforming`, `z_schemas__usage__marts`, `z_tables_views__select__analytics`), defined alongside the objects they protect
- Functional roles (`analyst`, `reporter`) compose those fine-grained roles into roles users are actually granted — `analyst` gets usage on all schemas, `reporter` is scoped to just `marts`

### 3. Declarative reconciliation
- `deploy` creates new objects, alters changed ones, leaves matching ones untouched, and **drops** managed objects that are no longer defined

## Difference from Snowcap

| | Snowcap (`main`) | Snowflake DCM (this branch) |
|---|---|---|
| Definition format | YAML (`resources/*.yml`) | SQL `DEFINE` + `GRANT` (`sources/definitions/*.sql`) |
| Runner | `uvx snowcap plan/apply` | `uvx ... snow dcm plan/deploy` |
| State | Reads live Snowflake state | Reads live Snowflake state |
| Templating / DRY | `for_each` over `vars` | Jinja (`{% for %}`, macros, templating configs) |
| Manages USER objects | ✅ creates users | ❌ not a supported object type — grants to existing users only |
| Drop-on-remove scope | Opt-in per type via `--sync_resources` (DB/schema excluded) | All managed types, **including databases/schemas** — always `./plan.sh` first |

<a name="difference-from-snowcap-users"></a>
### Users
DCM Projects [do not manage `USER` objects](https://docs.snowflake.com/en/user-guide/dcm-projects/dcm-projects-supported-entities).
The Snowcap `users.yml` both **created** `fmercado`/`gomezn` and granted their
roles; here the users are assumed to already exist (provisioned by SCIM/your IdP
or a one-off `CREATE USER`), and `users.sql` manages only the **role grants**
declaratively. It also omits the `ACCOUNTADMIN`/`ORGADMIN` grants by default —
they're included as comments you can enable if your deploying role is allowed to
grant them.

## Workshop Takeaways

- Snowflake infrastructure and access control can be declared and version-controlled the same way application code is — with a native Snowflake feature, no extra tool to install
- A layered role hierarchy (fine-grained `z_*` roles → functional roles) scales access control cleanly as teams grow
- `snow dcm plan` makes infrastructure changes reviewable before they touch a live account
- Declarative tools differ in scope: know what each one will and won't drop (and which object types it manages) before you deploy

---

*This branch is a reference implementation of the Snowcap webinar concepts using Snowflake DCM Projects. Explore it alongside `main` and adapt for your own use cases.*
