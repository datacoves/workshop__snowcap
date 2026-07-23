#!/bin/bash
# deploy.sh
#
# Applies the definitions in sources/definitions/ to the target account:
# creates, alters or drops objects so Snowflake matches the desired state.
# This is the DCM equivalent of `snowcap apply`.
#
# IMPORTANT: `snow dcm deploy` reconciles ALL managed object types. Any object
# that was previously deployed by this project but has been removed from the
# definition files WILL BE DROPPED -- including databases and schemas. (The
# Snowcap version deliberately left `database` and `schema` out of
# --sync_resources so they were never dropped; DCM has no such carve-out, so
# review `./plan.sh` before every deploy.)
#
# Pass --alias "some label" (or any other `snow dcm deploy` flag) through, e.g.
#   ./deploy.sh --alias "workshop baseline"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/_env.sh"

echo "=========="
echo "Using SNOWFLAKE_ACCOUNT=$SNOWFLAKE_ACCOUNT"
echo "DCM project: $DCM_PROJECT"
echo "=========="

"${SNOW[@]}" dcm deploy "$DCM_PROJECT" \
    --from . \
    "${SNOW_CONN[@]}" \
    "$@"
