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
    let
      # These arguments, and only these, will vary by system; the rest of the
      # code is portable, and refer to these args where applicable
      args = rec {
        hostname = "fixthislater";
        domain = "com";
        fqdn = "${hostname}.${domain}";
        root_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN6iC2Erg+IjdAGib4lzJ34HLICZ2NZqug1Wx8LSIt6Z admin@${fqdn}";
      };
    in
    {
      nixosConfigurations.fixthislater = nixpkgs.lib.nixosSystem {
        specialArgs = args;
        modules = nixpkgs.lib.filesystem.listFilesRecursive ./modules ++ [
          disko.nixosModules.disko
          mailserver.nixosModule
        ];
      };
    }
    //
    # Define apps for building & rebuilding the server's OS using the repo
    # config files
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      fqdn = args.fqdn;
    in {
      apps = rec {
        create = {
          type = "app";
          program = toString (pkgs.writers.writeBash "server_config_create" ''
            nix run \
              --extra-experimental-features 'nix-command flakes' \
              github:nix-community/nixos-anywhere -- \
                --flake . \
                --target-host root@${fqdn} \
                --build-on remote \
                --use-substitutes
          '');
        };
        update = {
          type = "app";
          program = toString (pkgs.writers.writeBash "server_config_update" ''
            nixos-rebuild switch \
              --flake . \
              --build-host root@${fqdn} \
              --target-host root@${fqdn}
          '');
        };
        default = update;
      };
    });
}
