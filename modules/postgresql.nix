{ lib, ... }:
{ services.postgresql = {
  enable = true;
  ensureDatabases = [ "keycloak" ];
  ensureUsers = [
    {
      name = "keycloak";
      ensureDBOwnership = true;
      ensureClauses.login = true;
    }
  ];
  authentication = lib.mkOverride 49 ''
    # TYPE  DATABASE        USER            ADDRESS                 METHOD
    local   all             postgres                                trust
    local   keycloak        keycloak                                trust
  '';
}; }