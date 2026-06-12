{ rootKey, ... }:
{ users.users = {
  root.openssh.authorizedKeys.keys = [ rootKey ];

  # Add nginx user to acme group so it can read certs
  nginx.extraGroups = [ "acme" ];
}; }