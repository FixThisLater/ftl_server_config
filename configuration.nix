{ modulesPath, lib, pkgs, config, ... }:
let
  domain = "fixthislater.com";
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

  system.stateVersion = "24.05";

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;


  # Nix settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    access-tokens = [
      "gitlab.com=PAT:${builtins.getEnv "GL_READ_API_TOKEN"}"
    ];
  };

  environment.systemPackages = with pkgs; [
    curl
    git
    rsync
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN6iC2Erg+IjdAGib4lzJ34HLICZ2NZqug1Wx8LSIt6Z fixthislater@protonmail.com"
  ];

  # Add nginx user to acme group so it can read certs
  users.users.nginx.extraGroups = [ "acme" ];

    # Open needed ports
  networking.firewall.allowedTCPPorts = [
    80 # HTTP
    443 # HTTPS
  ];

    # Acme - TLS cert manager
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "fixthislater@protonmail.com";
    };
  };

  services.nginx = {

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
        ${domain} = ssl // {
          locations = {
            "/auth/" = {
              proxyPass = "http://127.0.0.1:${toString config.services.keycloak.settings.http-port}/auth/";
            };
            "/" = {
              root = "/srv/www/fixthislater.com";
              tryFiles = "$uri /index.html =404";
            };
          };
        };
        ${config.mailserver.fqdn} = ssl;
      };
  };

  mailserver = {
    enable = true;
    stateVersion = 3;
    fqdn = "mail.${domain}";
    domains = [ domain ];
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
  };

  # PostgreSQL
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "keycloak" ];
    ensureUsers = [
      {
        name = "keycloak";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
    authentication = lib.mkOverride 49 ''
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      local   postgres        postgres                                trust
      local   keycloak        keycloak                                trust
    '';
  };

  # Keycloak
  services.keycloak = {
    enable = true;
    initialAdminPassword = "changeme";
    settings = {
      hostname = "fixthislater.com";
      http-enabled = true;
      http-port = 8080;
      http-relative-path = "/auth";
      proxy-headers = "xforwarded";
    };
    database.host = "/run/postgresql";
    plugins = with pkgs.keycloak.plugins; [
      junixsocket-common
      junixsocket-native-common
    ];
  };

  services.openldap = {
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
  };

}
