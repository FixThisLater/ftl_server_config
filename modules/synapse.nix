{ config, ... }:
{ services.matrix-synapse = {
  enable = true;
  extraConfigFiles = [ config.sops.templates.synapse-config.path ];
  settings.server_name = config.networking.fqdn;
  settings.public_baseurl = "https://${config.networking.fqdn}";
  extras = [ "oidc" ];
  settings.listeners = [ {
    port = 8008;
    bind_addresses = [ "::1" ];
    type = "http";
    tls = false;
    x_forwarded = true;
    resources = [ {
      names = [ "client" "openid"];
      compress = true;
    } ];
  } ];
}; }