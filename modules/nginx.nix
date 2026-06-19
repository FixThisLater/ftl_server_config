{ pkgs, lib, config, ... }:
let 
  fqdn = config.networking.fqdn; 
  # Makes standard ".well-known" file contents with the input as the response
  # payload.
  # Source: https://nixos.org/manual/nixos/stable/index.html#module-services-matrix-synapse
  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${data}';
  '';
in
{ 

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "admin@${fqdn}";
      group = config.services.nginx.group;
      dnsProvider = "hetzner";
      credentialFiles.HETZNER_API_TOKEN_FILE = "/run/secrets/hetzner-api-token";
    };
    certs.${fqdn} = { extraDomainNames = [ "*.${fqdn}" ]; };
  };

  services.nginx = {
    
    appendHttpConfig = ''
      error_log stderr;
      
      log_format custom
        '$remote_addr - $remote_user [$time_local]  $status '
        '"$host" "$request" $body_bytes_sent "$http_referer" '
        '"$http_user_agent" "$http_x_forwarded_for"';
      
      access_log syslog:server=unix:/dev/log custom;
    '';

    enable = true;

    # enable recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    
    clientMaxBodySize = "50M";

    virtualHosts = 
      let 
        rProxy = port: { proxyPass = "http://127.0.0.1:${toString port}"; };
        defaults = {
          forceSSL = true;
          useACMEHost = fqdn;
        };
        favicon = {"~ /favicon*.ico".alias = "/srv/www/${fqdn}/favicon.ico"; };
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
            extraConfig = mkWellKnown (
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
        "${config.services.keycloak.settings.hostname}".locations = {
          "= /".return = "301 /realms/main/account";
          "/" = rProxy config.services.keycloak.settings.http-port;
        };
        "wiki.${fqdn}".locations = favicon // {
          "/" = rProxy config.services.wiki-js.settings.port;
        };
        "${config.services.forgejo.settings.server.DOMAIN}".locations = favicon // {
          "/" = rProxy config.services.forgejo.settings.server.HTTP_PORT;
        };
      };
  };
}