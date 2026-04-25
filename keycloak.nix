{ pkgs, ... }:
{ services.keycloak = {
  enable = true;
  initialAdminPassword = "changeme";
  settings = {
    hostname = "fixthislater.com";
    http-enabled = true;
    http-port = 8080;
    http-relative-path = "/auth";
    proxy-headers = "xforwarded";
  };
  database.host = "/run/postgresql";
  plugins = with pkgs.keycloak.plugins; [
    junixsocket-common
    junixsocket-native-common
  ];
}; }