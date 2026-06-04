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
  authentication = lib.mkOverride 49 (builtins.readFile ../configs/pg_hba.conf);
}; }