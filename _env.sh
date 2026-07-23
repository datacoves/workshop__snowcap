#!/bin/bash
# _env.sh
#
# Shared helper sourced by setup.sh, plan.sh and deploy.sh. It:
#   1. cd's to the repo root (where manifest.yml lives)
#   2. loads .env
#   3. validates the required Snowflake connection variables
#   4. builds the SNOW_CONN array of flags used for every snow command
#   5. exposes DCM_PROJECT / DCM_DB / DCM_SCHEMA
#
# It is meant to be *sourced*, not executed.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Load .env if it exists
if [ -f .env ]; then
    set -a
    . ./.env
    set +a
fi

# Validate required variables
missing=()
[ -z "$SNOWFLAKE_ACCOUNT" ] && missing+=("SNOWFLAKE_ACCOUNT")
[ -z "$SNOWFLAKE_USER" ] && missing+=("SNOWFLAKE_USER")
[ -z "$SNOWFLAKE_ROLE" ] && missing+=("SNOWFLAKE_ROLE")
[ -z "$SNOWFLAKE_PRIVATE_KEY_PATH" ] && missing+=("SNOWFLAKE_PRIVATE_KEY_PATH")

if [ ${#missing[@]} -gt 0 ]; then
    echo "Error: Missing required environment variables:"
    for var in "${missing[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "Create a .env file (copy .env.sample) with:"
    echo ""
    echo "  SNOWFLAKE_ACCOUNT=your_account         # Account identifier (ORG-ACCOUNT)"
    echo "  SNOWFLAKE_USER=your_user               # Service account username"
    echo "  SNOWFLAKE_ROLE=ACCOUNTADMIN            # Role used to deploy the project"
    echo "  SNOWFLAKE_PRIVATE_KEY_PATH=~/.ssh/key  # Path to private key"
    echo "  SNOWFLAKE_AUTHENTICATOR=SNOWFLAKE_JWT"
    exit 1
fi

# DCM project identifier: DB.SCHEMA.PROJECT (override in .env)
DCM_PROJECT="${DCM_PROJECT:-dcm.projects.workshop}"
DCM_DB="${DCM_PROJECT%%.*}"
_rest="${DCM_PROJECT#*.}"
DCM_SCHEMA="${_rest%%.*}"

# Connection flags shared by every snow invocation. We use a temporary
# connection (-x) built entirely from the .env values, so no connections.toml
# is required.
SNOW_CONN=(
    --temporary-connection
    --account "$SNOWFLAKE_ACCOUNT"
    --user "$SNOWFLAKE_USER"
    --role "$SNOWFLAKE_ROLE"
    --private-key-file "$SNOWFLAKE_PRIVATE_KEY_PATH"
    --authenticator "${SNOWFLAKE_AUTHENTICATOR:-SNOWFLAKE_JWT}"
)

# Pin the Snowflake CLI; run it with `uvx` so no separate install is needed.
SNOW=(uvx --from snowflake-cli snow)
