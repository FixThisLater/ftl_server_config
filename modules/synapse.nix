{ config, pkgs, ... }:
let
  synapseConfig = pkgs.writeText "synapse-config.yaml" ''
    matrix_authentication_service:
      enabled: true
      endpoint: http://127.0.0.1:8081/
      secret_path: /run/secrets/mas/secret-synapse
  '';
in
{ services.matrix-synapse = {
  enable = true;
  extraConfigFiles = [ synapseConfig ];
  settings.server_name = config.networking.fqdn;
  settings.public_baseurl = "https://${config.networking.fqdn}";
  extras = [ "oidc" ];
  settings.listeners = [ {
    port = 8008;
    bind_addresses = [ "127.0.0.1" ];
    type = "http";
    tls = false;
    x_forwarded = true;
    resources = [ {
      names = [ "client" "openid"];
      compress = true;
    } ];
  } ];
}; }