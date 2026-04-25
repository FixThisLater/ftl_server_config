{ ... }:
{ mailserver = {
  enable = true;
  stateVersion = 3;
  fqdn = "mail.fixthislater.com";
  domains = [ "fixthislater.com" ];
  certificateScheme = "acme";
  ldap = {
    enable = true;
    uris = [ "ldap:///" ];
    bind = {
      dn = "cn=admin,dc=fixthislater,dc=com";
      passwordFile = "/run/secrets/ldap_admin_pw";
    };
    searchBase = "ou=users,dc=fixthislater,dc=com";
  };
}; }