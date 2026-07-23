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

# 1. Home database + schema for the DCM project object
"${SNOW[@]}" sql "${SNOW_CONN[@]}" -q \
    "CREATE DATABASE IF NOT EXISTS ${DCM_DB}; CREATE SCHEMA IF NOT EXISTS ${DCM_DB}.${DCM_SCHEMA};"

# 2. The DCM project object itself (no-op if it already exists)
"${SNOW[@]}" dcm create "$DCM_PROJECT" \
    --if-not-exists \
    --from . \
    "${SNOW_CONN[@]}"

echo ""
echo "Done. Next: ./plan.sh to preview, then ./deploy.sh to apply."
