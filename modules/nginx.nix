{ lib, config, fqdn, ... }:
{ services.nginx = {

  enable = true;

  # enable recommended settings
  recommendedGzipSettings = true;
  recommendedOptimisation = true;
  recommendedTlsSettings = true;
  recommendedProxySettings = true;

  virtualHosts =
    let
      set_defaults = vhost: vhost // {
        forceSSL = true;
        enableACME = true;
      };
      rproxy = port: {
        locations."/".proxyPass = "http://127.0.0.1:${toString port}";
      };
    in 
    lib.mapAttrs (name: value: set_defaults value) {
      ${fqdn} = {
        locations."/" = {
            root = "/srv/www/${fqdn}";
            tryFiles = "$uri /index.html =404";
        };
      };
      ${config.mailserver.fqdn} = {};
      ${config.services.keycloak.settings.hostname} = rproxy config.services.keycloak.settings.http-port;
      ${config.services.forgejo.settings.server.DOMAIN} = 
        rproxy config.services.forgejo.settings.server.HTTP_PORT // {
          extraConfig = ''
            client_max_body_size 512M;
          '';
        };
    };
}; }