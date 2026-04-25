{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  system.stateVersion = "24.05";

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  
  services.openssh.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes" 
  ];

  networking.firewall.allowedTCPPorts = [
    80 # HTTP
    443 # HTTPS
  ];

  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@fixthislater.com";
  };

}
