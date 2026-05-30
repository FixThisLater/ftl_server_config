nixos-rebuild switch \
  --flake . \
  --build-host root@@fqdn@ \
  --target-host root@@fqdn@