{ config, fqdn, ... }:
{ services.nginx = {

  enable = true;

  # enable recommended settings
  recommendedGzipSettings = true;
  recommendedOptimisation = true;
  recommendedTlsSettings = true;
  recommendedProxySettings = true;

  virtualHosts =
    let
      # Common SSL-related attributes
      ssl = {
        forceSSL = true;
        enableACME = true;
      };
      port = port: ssl // {
        locations."/".proxyPass = "http://127.0.0.1:${toString port}";
      };
    in {
      ${fqdn} = ssl // {
        locations."/" = {
            root = "/srv/www/${fqdn}";
            tryFiles = "$uri /index.html =404";
        };
      };
      ${config.mailserver.fqdn} = ssl;
      ${config.services.keycloak.settings.hostname} = port config.services.keycloak.settings.http-port;
    };
}; }