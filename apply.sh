#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

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
    echo "Create a .env file with:"
    echo ""
    echo "  SNOWFLAKE_ACCOUNT=your_account        # Account identifier"
    echo "  SNOWFLAKE_USER=your_user              # Service account username"
    echo "  SNOWFLAKE_ROLE=SECURITYADMIN          # Role for applying changes"
    echo "  SNOWFLAKE_PRIVATE_KEY_PATH=~/.ssh/key # Path to private key"
    echo "  SNOWFLAKE_AUTHENTICATOR=SNOWFLAKE_JWT"
    exit 1
fi

echo "=========="
echo "Using SNOWFLAKE_ACCOUNT=$SNOWFLAKE_ACCOUNT"
echo "=========="

uvx snowcap apply \
    --config resources/ \
    --sync_resources role,grant,role_grant,warehouse,user \
    "$@"
