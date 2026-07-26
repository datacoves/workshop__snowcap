#!/bin/bash
# setup.sh
#
# One-time bootstrap. A DCM Project is itself a Snowflake object that lives in a
# schema, so we first create a small "home" database/schema to hold it, then
# create the (empty) DCM project object. After this you only ever run
# ./plan.sh and ./deploy.sh.
#
# This is the DCM equivalent of the state backend other IaC tools need: the
# analytics database, warehouse, roles and grants are all still managed
# declaratively -- only the project object's home is created imperatively.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/_env.sh"

echo "=========="
echo "Using SNOWFLAKE_ACCOUNT=$SNOWFLAKE_ACCOUNT"
echo "Creating home for DCM project: $DCM_PROJECT"
echo "=========="

# 1. Home database + schema for the DCM project object, plus the grants that
#    let SNOWFLAKE_ROLE (SECURITYADMIN) own the project from here on. Only this
#    bootstrap needs the elevated role; plan.sh and deploy.sh run as the role
#    from .env.
"${SNOW[@]}" sql "${SNOW_CONN[@]}" -q \
    "USE ROLE ${DCM_SETUP_ROLE};
     CREATE DATABASE IF NOT EXISTS ${DCM_DB};
     CREATE SCHEMA IF NOT EXISTS ${DCM_DB}.${DCM_SCHEMA};
     GRANT USAGE ON DATABASE ${DCM_DB} TO ROLE ${SNOWFLAKE_ROLE};
     GRANT USAGE ON SCHEMA ${DCM_DB}.${DCM_SCHEMA} TO ROLE ${SNOWFLAKE_ROLE};
     GRANT CREATE DCM PROJECT ON SCHEMA ${DCM_DB}.${DCM_SCHEMA} TO ROLE ${SNOWFLAKE_ROLE};
     GRANT CREATE DATABASE ON ACCOUNT TO ROLE ${SNOWFLAKE_ROLE};
     GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE ${SNOWFLAKE_ROLE};"

# 2. The DCM project object itself (no-op if it already exists)
"${SNOW[@]}" dcm create "$DCM_PROJECT" \
    --if-not-exists \
    --from . \
    "${SNOW_CONN[@]}"

echo ""
echo "Done. Next: ./plan.sh to preview, then ./deploy.sh to apply."
