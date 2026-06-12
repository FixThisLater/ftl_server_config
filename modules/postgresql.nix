{ config, lib, helpers, ... }:
{ services.postgresql = {
  enable = true;
  ensureDatabases = [ "forgejo" "keycloak" "matrix-synapse" "mas" "wiki" ];
  # Define a user with DB ownership and login permissions for each DB
  ensureUsers = helpers.stdPgUsers config.services.postgresql.ensureDatabases;
  initdbArgs = [ "--lc-collate=C" "--lc-ctype=C" ];
  authentication = lib.mkOverride 49 (builtins.readFile ../configs/pg_hba.conf);
}; }