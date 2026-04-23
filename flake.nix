{
  description = "Config of the primary Fix This Later server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, flake-utils, disko, ... }:
    {
      nixosConfigurations.ftl = nixpkgs.lib.nixosSystem {
        modules = [
          ./configuration.nix
          disko.nixosModules.disko
        ];
      };
    }
    //
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      server_ip = "46.225.136.43";
    in {
      apps = {
        create = {
          type = "app";
          program = toString (pkgs.writers.writeBash "ftl_server_config_create" ''
            nix run \
              --extra-experimental-features 'nix-command flakes' \
              github:nix-community/nixos-anywhere -- \
                --flake . \
                --target-host root@${server_ip} \
                --build-on remote
          '');
        };
        update = {
          type = "app";
          program = toString (pkgs.writers.writeBash "ftl_server_config_update" ''
            nixos-rebuild switch \
              --flake .#ftl \
              --target-host root@${server_ip}
          '');
        };
      };
    });
}
