{ pkgs, lib, config, helpers, ... }:
let fqdn = config.networking.fqdn; in
{ services.nginx = {

  enable = true;

  # enable recommended settings
  recommendedGzipSettings = true;
  recommendedOptimisation = true;
  recommendedTlsSettings = true;
  recommendedProxySettings = true;
  
  clientMaxBodySize = "50M";

  virtualHosts = 
    let 
      rProxy = helpers.rProxy;
      defaults = {
        forceSSL = true;
        enableACME = true;
      };
      favicon = {"= /favicon.ico".alias = "/srv/www/${fqdn}/favicon.ico"; };
      matrixClientConfig = {
        "m.homeserver".base_url =
          "https://${fqdn}";
      };
    in
    # Add defaults to all the virtual hosts
    lib.mapAttrs (name: value: lib.mergeAttrs value defaults) {
      "${fqdn}".locations = favicon // {
        "~ ^/_matrix/client/(.*)/(login|logout|refresh)" = rProxy 8081;
        "~ ^(/_matrix|/_synapse/client|/_synapse/mas)" = rProxy 8008;
        "= /.well-known/matrix/client" = {
          extraConfig = helpers.mkWellKnown (
            builtins.toJSON matrixClientConfig
          );
        };
        "/" = {
          root = "/srv/www/${fqdn}";
          tryFiles = "$uri /index.html =404";
        };
      };
      "chat.${fqdn}" = {
        locations = favicon;
        root = pkgs.element-web.override { conf = {
          default_server_config = matrixClientConfig;
          default_country_code = "US";
          room_directory.servers = [ fqdn ];
          default_theme = "dark";
          permalink_prefix = "https://chat.${fqdn}";
          mobile_guide_toast = false;
          disable_3pid_login = true;
          disable_guests = true;
          embedded_pages = {
            home_url = "https://chat.${fqdn}";
            login_for_welcome = true;
          };
          logout_redirect_url = "https://chat.fixthislater.com";
          sso_redirect_options.immediate = true;
          enable_presence_by_hs_url = {
            "https://matrix.org" = false;
            "https://matrix-client.matrix.org" = false;
          };
        }; };
      };
      "mas.${fqdn}".locations = favicon // {"/" = rProxy 8081; };
      "${config.mailserver.fqdn}" = {locations = favicon; };
      "${config.services.keycloak.settings.hostname}".locations = favicon // {
        "/" = rProxy config.services.keycloak.settings.http-port;
      };
      "wiki.${fqdn}".locations = favicon // {
        "/".proxyPass = "http://127.0.0.1:${toString config.services.wiki-js.settings.port}";
      };
      "${config.services.forgejo.settings.server.DOMAIN}".locations = favicon // {
        "/" = rProxy config.services.forgejo.settings.server.HTTP_PORT;
      };
    };
}; }