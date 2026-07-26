# Webinar - Snowcap (Snowflake DCM edition)

> **Hosted by [Datacoves](https://datacoves.com)** - Enterprise DataOps platform with managed dbt Core and Airflow for data transformation and orchestration.

This branch reimplements the [Snowcap](https://snowcap.datacoves.com) workshop
using **[Snowflake DCM Projects](https://docs.snowflake.com/en/user-guide/dcm-projects/dcm-projects-overview)**
(Declarative Change Management) — Snowflake's own native, declarative
object-management feature — instead of Snowcap. The **same** database, schemas,
warehouse, role hierarchy and grants are defined; only the tool that declares
and applies them changes.

> 📚 This workshop exists in **three** implementations, one per branch:
> [`main`](../../tree/main) (Snowcap), **`snowflake_dcm`** (this one), and
> [`terraform`](../../tree/terraform). All three declare the same objects and
> read the same `.env`, so you can switch branches and re-run. See
> [How this compares to the other branches](#how-this-compares-to-the-other-branches).

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
- **`users.sql`** — grants `analyst`/`reporter`/`accountadmin` to the human user `gomezn`

### 📁 Root Files
- **`manifest.yml`** — the DCM project manifest (`manifest_version`, `type: DCM_PROJECT`, and a `targets` block — see [Manifest targets](#manifest-targets))
- **`_env.sh`** — shared helper: loads `.env`, validates it, and builds the `snow` connection flags
- **`setup.sh`** — one-time bootstrap: creates the home DB/schema for the project object, grants the deploying role the privileges it needs, and runs `snow dcm create`
- **`plan.sh`** — runs `snow dcm plan` (preview, the DCM equivalent of `snowcap plan`)
- **`deploy.sh`** — runs `snow dcm deploy` (apply, the DCM equivalent of `snowcap apply`)
- **`.env.sample`** — template for the Snowflake connection variables
- **`dcm_test.sql`** — worksheet for verifying access: switches to `analyst`/`reporter` and queries the `analytics` schemas

## How to Run It

### Prerequisites
- A Snowflake account, plus a role that can create databases, schemas, warehouses, roles and grants. DCM runs the **entire** deployment as one role, so it must hold the union of every privilege the project needs — see [Roles and privileges](#roles-and-privileges)
- `uv`/`uvx` installed — the Snowflake CLI is run via `uvx --from snowflake-cli snow`, so **no separate install is required**
- Key-pair (JWT) authentication configured for your Snowflake user, registered on the **target** account (`ALTER USER <you> SET RSA_PUBLIC_KEY='...'`). A key that works on one account is not automatically valid on another
- Any user referenced in `sources/definitions/users.sql` must already exist — see [Difference from Snowcap](#difference-from-snowcap-users)

### 1. Configure the connection
```bash
cp .env.sample .env
# Fill in SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, SNOWFLAKE_ROLE, SNOWFLAKE_PRIVATE_KEY_PATH
```
The scripts read `.env` and pass a **temporary connection** to `snow` (via
`--temporary-connection` plus `--account/--user/--role/...`), so you do **not**
need a `connections.toml`.

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

<a name="roles-and-privileges"></a>
## Roles and privileges

**DCM executes an entire deployment as a single session role.** There is no
per-object role switching: `USE ROLE` is rejected at compile time, because
definition files accept only `DEFINE` and `GRANT` statements.

```
001525 (0A000): Unexpected statement [USE ROLE SYSADMIN],
only DEFINE statements are allowed in DCM project definitions files.
```

This is a real difference from Terraform, where you can alias several providers
with different roles and choose one per resource. With DCM, the deploying role
must hold the **union** of every privilege the project needs — here that spans
two normally-separate duties: `CREATE ROLE` (a `SECURITYADMIN` concern) and
`CREATE DATABASE` / `CREATE WAREHOUSE` (a `SYSADMIN` concern).

`setup.sh` handles this by using `ACCOUNTADMIN` **only** for the one-time
bootstrap (set `DCM_SETUP_ROLE` to override), where it grants the deploying role
what it needs:

```sql
GRANT CREATE DCM PROJECT ON SCHEMA dcm.projects TO ROLE <SNOWFLAKE_ROLE>;
GRANT CREATE DATABASE  ON ACCOUNT TO ROLE <SNOWFLAKE_ROLE>;
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE <SNOWFLAKE_ROLE>;
```

`plan.sh` and `deploy.sh` then run as the ordinary `SNOWFLAKE_ROLE` from `.env`.

### ⚠️ Don't transfer ownership away from the deploying role

`GRANT OWNERSHIP` *does* compile, so it is tempting to let `SECURITYADMIN`
create a warehouse and then hand it to `SYSADMIN`:

```sql
-- Compiles and deploys once. Then breaks every later run.
GRANT OWNERSHIP ON WAREHOUSE wh_transforming TO ROLE sysadmin;
```

The first `deploy` succeeds. Every subsequent `plan`/`deploy` fails, because the
deploying role just gave away the object it has to reconcile:

```
Warehouse 'WH_TRANSFORMING' already exists, but current role has
no privileges on it.
```

Recovering requires an out-of-band `ACCOUNTADMIN` statement, which defeats the
point of declarative management:

```sql
GRANT OWNERSHIP ON WAREHOUSE wh_transforming
  TO ROLE securityadmin COPY CURRENT GRANTS;
```

If you genuinely need separation of duties, split the work into **separate DCM
projects** deployed by different roles. Note the trade-off: DCM resolves
dependencies only *within* a project, so a cross-project reference (`roles.sql`
here refers to `z_wh__wh_transforming` from `warehouses.sql`) would no longer
resolve and those grants would have to move or be managed manually.

<a name="manifest-targets"></a>
## Manifest targets

`manifest_version: 2` requires at least one entry under `targets`. The CLI
resolves the target **before** it looks at any identifier passed on the command
line, so a manifest without one fails even when `plan.sh`/`deploy.sh` pass a
fully-qualified project name:

```
No target specified and no default_target defined in manifest.
```

A single target is automatically treated as the default, so no `default_target`
key is needed. Only `project_name` is required. `account_identifier` and
`project_owner` are deliberately omitted here so the file stays portable across
workshop accounts — the CLI prints a warning that it cannot cross-check them,
which is harmless. Set them if you want that safety net.

### ⚠️ Jinja is rendered inside SQL comments

DCM renders each `.sql` file as a Jinja template *before* parsing the SQL, and
`--` comments are **not** exempt. Writing a Jinja tag in a comment to explain
templating will fail the build:

```
Failed to render Jinja2 template due to [jinja2.exceptions.TemplateSyntaxError]
- Expected an expression, got 'end of statement block'.
```

Describe Jinja constructs in prose, or escape them with `{% raw %}`.

## Difference from Snowcap

| | Snowcap (`main`) | Snowflake DCM (this branch) |
|---|---|---|
| Definition format | YAML (`resources/*.yml`) | SQL `DEFINE` + `GRANT` (`sources/definitions/*.sql`) |
| Runner | `uvx snowcap plan/apply` | `uvx ... snow dcm plan/deploy` |
| State | Reads live Snowflake state | Reads live Snowflake state |
| Templating / DRY | `for_each` over `vars` | Jinja (`{% for %}`, macros, templating configs) |
| Manages USER objects | ✅ creates users | ❌ not a supported object type — grants to existing users only |
| Drop-on-remove scope | Opt-in per type via `--sync_resources` (DB/schema excluded) | All managed types, **including databases/schemas** — always `./plan.sh` first |
| Role switching mid-run | n/a — single role | ❌ none; `USE ROLE` rejected. Deploying role needs the union of all privileges |

<a name="difference-from-snowcap-users"></a>
### Users
DCM Projects [do not manage `USER` objects](https://docs.snowflake.com/en/user-guide/dcm-projects/dcm-projects-supported-entities).
The Snowcap `users.yml` both **creates** `gomezn` and grants its roles; here the
user is assumed to already exist (provisioned by SCIM/your IdP or a one-off
`CREATE USER`), and `users.sql` manages only the **role grants** declaratively.
This is the one part of the workshop that does not translate 1:1.

Referencing a user that does not exist fails at compile time, before anything is
planned:

```
Unresolved or ambiguous dependency: Dependency User SOMEUSER
does not exist or not authorized
```

So on a fresh account, create the user first:

```sql
CREATE USER IF NOT EXISTS gomezn TYPE = PERSON;
```

`users.sql` grants `analyst`, `reporter` and `accountadmin`, matching
`resources/users.yml` on `main`. `ORGADMIN` is deliberately absent from all three
branches — see [Don't add ORGADMIN](#dont-add-orgadmin) below.

<a name="how-this-compares-to-the-other-branches"></a>
## How this compares to the other branches

All three branches declare the same objects and all three plan cleanly. What
differs is how each tool decides **what already exists** and **who owns it** —
verified by running all three against the same account.

| | Snowcap ([`main`](../../tree/main)) | DCM (this branch) | Terraform ([`terraform`](../../tree/terraform)) |
|---|---|---|---|
| **Detects existing objects** | Reads live Snowflake | Reads live Snowflake | ❌ **State file only** |
| **Manages `USER` objects** | ✅ creates them | ❌ **not supported** | ✅ creates them |
| **Object ownership** | Assigns defaults (`SYSADMIN` / `USERADMIN`) | Whoever deployed | Whoever applied |
| **Drop-on-remove** | Opt-in via `--sync_resources`; DB/schema excluded | **All** managed types, incl. DB/schema | Anything removed from `.tf` |
| **Role switching mid-run** | Single role | Single role; `USE ROLE` rejected | Single role (aliases possible, unused) |

`ORGADMIN` is not in this table because all three behave identically: none grant
it, so none of them differ in what they produce. It is a separate topic — see
[Don't add `ORGADMIN`](#dont-add-orgadmin).

### What this branch does best

DCM and Snowcap both read live Snowflake state, so both correctly report
near-zero drift against an account that already has the objects. Terraform, whose
state file starts empty, plans to create all 34 resources again — it needs a
clean account or `terraform import`.

### Where this branch is most constrained

**It cannot manage `USER` objects.** `gomezn` must already exist; DCM manages
only the role grants. Snowcap and Terraform both create users. This is the one
part of the workshop that does not translate 1:1 — see
[Difference from Snowcap](#difference-from-snowcap-users).

**Its objects end up owned by the deploying role.** DCM has no ownership model in
definition files, so everything belongs to whoever ran `deploy` (here
`SECURITYADMIN`). Snowcap assigns implicit default owners, so if you deploy this
branch and then run Snowcap against the same account, Snowcap plans **14
ownership transfers** to move everything to `SYSADMIN`/`USERADMIN`:

```
» Plan: 3 to create, 1 to update, 14 to transfer, 0 to drop.
~ TRANSFER: ANALYTICS       owner: SECURITYADMIN → SYSADMIN
~ TRANSFER: WH_TRANSFORMING owner: SECURITYADMIN → SYSADMIN
```

Pick one tool per account. Two of them will fight over ownership on every run,
and as noted above, handing DCM's objects to another role breaks DCM's own next
run.

<a name="dont-add-orgadmin"></a>
### Don't add `ORGADMIN`

None of the three branches grant `ORGADMIN`, and it's worth knowing why. The role
exists only in an organization's **primary account**; anywhere else it simply
isn't there, so referencing it fails at compile time exactly like a missing user.

Enabling it is an organization-level operation that must be run by hand from an
account that already holds the role:

```sql
USE ROLE ORGADMIN;
ALTER ACCOUNT my_account SET IS_ORG_ADMIN = TRUE;
```

**DCM cannot do this at all.** `ACCOUNT` is not among its
[supported entities](https://docs.snowflake.com/en/user-guide/dcm-projects/dcm-projects-supported-entities),
and the docs say so directly: *"Assigning the policy to an account, user, or
integration must be done outside of DCM Projects, using `ALTER ACCOUNT`,
`ALTER USER`, or `ALTER SECURITY INTEGRATION`."* Snowcap has no equivalent
resource either. Terraform is the only one that could, via `snowflake_account`,
which manages accounts rather than grants.

## Workshop Takeaways

- Snowflake infrastructure and access control can be declared and version-controlled the same way application code is — with a native Snowflake feature, no extra tool to install
- A layered role hierarchy (fine-grained `z_*` roles → functional roles) scales access control cleanly as teams grow
- `snow dcm plan` makes infrastructure changes reviewable before they touch a live account
- Declarative tools differ in scope: know what each one will and won't drop (and which object types it manages) before you deploy
- Know the **execution model**, not just the syntax: DCM's single-role deployment shapes how you grant privileges and how far you can take separation of duties

---

*This branch is a reference implementation of the Snowcap webinar concepts using Snowflake DCM Projects. Explore it alongside `main` and adapt for your own use cases.*
