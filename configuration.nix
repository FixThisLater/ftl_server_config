{ modulesPath, pkgs, config, ... }:
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
        # Function for web-hosts that just need path specified
        path = path: ssl // {
          root = path;
          locations."/".tryFiles = "$uri /index.html =404";
        };
        # Function for reverse-proxies that just need port specified
        port = port: ssl // {
          locations."/".proxyPass = "http://127.0.0.1:${toString port}/";
        };
      in {
        ${domain} = path "/srv/www/fixthislater.com";
        ${config.mailserver.fqdn} = ssl;
      };
  };

  mailserver = {
    enable = true;
    stateVersion = 3;
    fqdn = "mail.${domain}";
    domains = [ domain ];
    certificateScheme = "acme";
    loginAccounts = {
      "admin@fixthislater.com" = {
        hashedPassword = "$y$j9T$qpFfZbzlc8n5v8SP7DKT2/$7moM8Qb/M1ZW1ZUsLSX/3g1J42VgtbvIUYKwgTd9H90";
      };
    };
  };
}
