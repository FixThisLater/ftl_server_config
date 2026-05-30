nix run \
  --extra-experimental-features 'nix-command flakes' \
  github:nix-community/nixos-anywhere -- \
    --flake . \
    --target-host root@@fqdn@ \
    --build-on remote \
    --use-substitutes
