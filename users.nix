{ ... }:
{ users.users = {
  root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN6iC2Erg+IjdAGib4lzJ34HLICZ2NZqug1Wx8LSIt6Z fixthislater@protonmail.com"
  ];

  # Add nginx user to acme group so it can read certs
  nginx.extraGroups = [ "acme" ];
}; }