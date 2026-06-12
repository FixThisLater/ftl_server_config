{ config, ... }:
let
  fjDomain = config.services.forgejo.settings.server.DOMAIN;
in
{ services.forgejo = {
  enable = true;
  database = {
    type = "postgres";
    createDatabase = false;
    socket = "/run/postgresql";
  };
  lfs.enable = true;
  settings = {
    DEFAULT = {
      APP_NAME = "# FIX THIS LATER";
    };
    server = {
      DOMAIN = "git.${config.networking.fqdn}";
      ROOT_URL = "https://${fjDomain}";
    };
#     mailer = {
#       ENABLED = true;
#       SMTP_ADDR = "mail.${fqdn}";
#       FROM = "git@${fqdn}";
#       USER = "git@${fqdn}";
#     };
  };
#   secrets = {
#     mailer.PASSWD = config.age.secrets.forgejo-mailer-password.path;
#   };
}; }