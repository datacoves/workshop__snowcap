#!/bin/bash
# plan.sh
#
# Shows what objects DCM would create, alter or drop to make Snowflake match the
# definitions in sources/definitions/ -- without changing anything. This is the
# DCM equivalent of `snowcap plan`.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/_env.sh"

echo "=========="
echo "Using SNOWFLAKE_ACCOUNT=$SNOWFLAKE_ACCOUNT"
echo "DCM project: $DCM_PROJECT"
echo "=========="

"${SNOW[@]}" dcm plan "$DCM_PROJECT" \
    --from . \
    "${SNOW_CONN[@]}" \
    "$@"
