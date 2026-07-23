-- users.sql
--
-- Grants the functional roles to human users. This mirrors the *grants* half of
-- resources/users.yml from the Snowcap version.
--
-- NOTE: DCM Projects do NOT manage USER objects (see the supported object types:
-- https://docs.snowflake.com/en/user-guide/dcm-projects/dcm-projects-supported-entities).
-- Snowcap could both create the users AND grant their roles; with DCM the users
-- must already exist (provisioned by your SCIM/IdP or a one-off CREATE USER),
-- and DCM manages the role grants declaratively. This is the one part of the
-- Snowcap setup that does not translate 1:1 to DCM.

GRANT ROLE analyst  TO USER fmercado;
GRANT ROLE reporter TO USER fmercado;

GRANT ROLE analyst  TO USER gomezn;
GRANT ROLE reporter TO USER gomezn;

-- The Snowcap version also granted ACCOUNTADMIN and ORGADMIN to these users.
-- Uncomment to match it exactly -- note the deploying role must itself hold
-- (and be allowed to grant) these roles; ORGADMIN in particular can only be
-- granted by ORGADMIN.
--
-- GRANT ROLE accountadmin TO USER fmercado;
-- GRANT ROLE orgadmin     TO USER fmercado;
-- GRANT ROLE accountadmin TO USER gomezn;
-- GRANT ROLE orgadmin     TO USER gomezn;
