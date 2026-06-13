{ config, lib, ... }:
let
  # Takes a list of desired PostgreSQL usernames and returns a list of 
  # PostgreSQL user attrsets with DB ownership and login enabled by default
  stdPgUsers =
    let
      stdPgUser = username: {
        name = username;
        ensureDBOwnership = true;
        ensureClauses.login = true;
      };
    in
    usernames: map stdPgUser usernames;
in
{ services.postgresql = {
  enable = true;
  ensureDatabases = [ "forgejo" "keycloak" "matrix-synapse" "mas" "wiki" ];
  ensureUsers = stdPgUsers config.services.postgresql.ensureDatabases;
  initdbArgs = [ "--lc-collate=C" "--lc-ctype=C" ];
  authentication = lib.mkOverride 49 ''
    # TYPE  DATABASE        USER            ADDRESS                 METHOD
    local   all             postgres                                trust
    local   keycloak        keycloak                                trust
    local   forgejo         forgejo                                 trust
    local   matrix-synapse  matrix-synapse                          trust
    local   mas             mas                                     trust
    local   wiki            wiki                                    trust
  '';
}; }