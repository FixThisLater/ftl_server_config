{ pkgs, fqdn, ... }:
{ services.keycloak = {
  enable = true;
  initialAdminPassword = "changeme";
  settings = {
    hostname = "auth.${fqdn}";
    http-enabled = true;
    http-port = 8080;
    proxy-headers = "xforwarded";
  };
  database.host = "/run/postgresql";
  plugins = with pkgs.keycloak.plugins; [
    junixsocket-common
    junixsocket-native-common
  ];
}; }