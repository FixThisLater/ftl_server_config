{ pkgs, ... }:
{ services.openldap = {
  enable = true;
  urlList = [ "ldap:///" ];
  settings.attrs.olcLogLevel = "conns config";
  settings.children = {
    "cn=schema".includes = [
      "${pkgs.openldap}/etc/schema/core.ldif"
      "${pkgs.openldap}/etc/schema/cosine.ldif"
      "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
    ];
    "olcDatabase={1}mdb".attrs = {
      objectClass = [ "olcDatabaseConfig" "olcMdbConfig" ];
      olcDatabase = "{1}mdb";
      olcDbDirectory = "/var/lib/openldap/data";
      olcSuffix = "dc=fixthislater,dc=com";
      olcRootDN = "cn=admin,dc=fixthislater,dc=com";
      olcRootPW.path = "/run/secrets/ldap_admin_pw";
      olcAccess = [
        /* custom access rules for userPassword attributes */
        ''{0}to attrs=userPassword
            by self write
            by anonymous auth
            by * none''
        /* allow read on anything else */
        ''{1}to *
            by * read''
      ];
    };
  };
}; }