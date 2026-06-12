{ config, hostName, domain, ... }:
{ mailserver = {
  enable = true;
  stateVersion = 3;
  fqdn = "mail.${config.networking.fqdn}";
  domains = [ config.networking.fqdn ];
  certificateScheme = "acme";
  ldap = {
    enable = true;
    uris = [ "ldap:///" ];
    bind = {
      dn = "cn=admin,dc=${hostName},dc=${domain}";
      passwordFile = "/run/secrets/ldap_admin_pw";
    };
    searchBase = "ou=users,dc=${hostName},dc=${domain}";
  };
}; }