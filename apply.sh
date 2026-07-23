#!/bin/bash
# apply.sh
#
# Loads .env, maps the SNOWFLAKE_* variables onto the Terraform variables the
# provider needs, and runs `terraform apply` -- the step that actually creates,
# alters or drops objects to match the .tf files, equivalent to `snowcap apply`.
#
# Pass extra flags through, e.g. ./apply.sh -auto-approve

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
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
    echo "  SNOWFLAKE_ACCOUNT=your_org-your_account   # Account identifier"
    echo "  SNOWFLAKE_USER=your_user                  # Service account username"
    echo "  SNOWFLAKE_ROLE=ACCOUNTADMIN               # Role for applying changes"
    echo "  SNOWFLAKE_PRIVATE_KEY_PATH=~/.ssh/key     # Path to private key"
    echo "  SNOWFLAKE_AUTHENTICATOR=SNOWFLAKE_JWT"
    exit 1
fi

# The Snowflake account identifier is ORG-ACCOUNT; the provider wants the two
# halves separately.
export TF_VAR_organization_name="${SNOWFLAKE_ACCOUNT%%-*}"
export TF_VAR_account_name="${SNOWFLAKE_ACCOUNT#*-}"
export TF_VAR_user="$SNOWFLAKE_USER"
export TF_VAR_role="$SNOWFLAKE_ROLE"
export TF_VAR_private_key_path="$SNOWFLAKE_PRIVATE_KEY_PATH"

echo "=========="
echo "Using SNOWFLAKE_ACCOUNT=$SNOWFLAKE_ACCOUNT"
echo "  organization_name=$TF_VAR_organization_name  account_name=$TF_VAR_account_name"
echo "=========="

terraform init -input=false
terraform apply "$@"
