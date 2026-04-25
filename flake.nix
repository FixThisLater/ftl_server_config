{
  description = "Config of the primary Fix This Later server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, flake-utils, disko, mailserver, ... }:
    {
      nixosConfigurations.ftl = nixpkgs.lib.nixosSystem {
        modules = [
          disko.nixosModules.disko
          mailserver.nixosModule
          ./general.nix
          ./users.nix
          ./system-packages.nix
          ./disk-config.nix
          ./postgresql.nix
          ./keycloak.nix
          ./mailserver.nix
          ./openldap.nix
          ./nginx.nix
        ];
      };
    }
    //
    # Define apps for building & rebuilding the server's OS using the repo
    # config files
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      server_ip = "46.225.136.43";
    in {
      apps = rec {
        create = {
          type = "app";
          program = toString (pkgs.writers.writeBash "ftl_server_config_create" ''
            nix run \
              --extra-experimental-features 'nix-command flakes' \
              github:nix-community/nixos-anywhere -- \
                --flake . \
                --target-host root@${server_ip} \
                --build-on remote \
                --use-substitutes
          '');
        };
        update = {
          type = "app";
          program = toString (pkgs.writers.writeBash "ftl_server_config_update" ''
            nixos-rebuild switch \
              --flake .#ftl \
              --build-host root@${server_ip} \
              --target-host root@${server_ip}
          '');
        };
        default = update;
      };
    });
}
