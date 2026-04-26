{ root_key, ... }:
{ users.users = {
  root.openssh.authorizedKeys.keys = [
    root_key
  ];

  # Add nginx user to acme group so it can read certs
  nginx.extraGroups = [ "acme" ];
}; }