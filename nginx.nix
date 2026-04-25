{ config, ... }:
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
    in {
      "fixthislater.com" = ssl // {
        locations."/" = {
            root = "/srv/www/fixthislater.com";
            tryFiles = "$uri /index.html =404";
        };
      };
      "auth.fixthislater.com" = ssl // {
        locations."/".proxyPass = "http://127.0.0.1:${toString config.services.keycloak.settings.http-port}";
      };
      ${config.mailserver.fqdn} = ssl;
    };
}; }