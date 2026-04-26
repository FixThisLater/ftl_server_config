{ hostname, domain, fqdn, ... }:
{ mailserver = {
  enable = true;
  stateVersion = 3;
  fqdn = "mail.${fqdn}";
  domains = [ fqdn ];
  certificateScheme = "acme";
  ldap = {
    enable = true;
    uris = [ "ldap:///" ];
    bind = {
      dn = "cn=admin,dc=${hostname},dc=${domain}";
      passwordFile = "/run/secrets/ldap_admin_pw";
    };
    searchBase = "cn=admin,dc=${hostname},dc=${domain}";
  };
}; }