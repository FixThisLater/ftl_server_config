{
  description = ''
    Config of the Fix This Later monolith server. All the distinctive 
    parameters are defined in "args.nix".
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, flake-utils, sops-nix, disko, mailserver, ... }:
    let 
      args = import ./args.nix;
    in
    {
      nixosConfigurations.fixthislater = nixpkgs.lib.nixosSystem {
        specialArgs = args;
        modules = nixpkgs.lib.filesystem.listFilesRecursive ./modules ++ [
          sops-nix.nixosModules.sops
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
        fqdn = "${args.hostName}.${args.domain}";
        replaceInBash = src: replacements: pkgs.lib.pipe replacements [
          (pkgs.replaceVars src)
          builtins.readFile
          (pkgs.writers.writeBash (builtins.baseNameOf src))
          toString
        ];
      in {
        apps = rec {
          create = {
            meta = { description = "Establish the server after VM creation."; };
            type = "app";
            program = replaceInBash ./programs/create.sh { inherit fqdn; };
          };
          update = {
            meta = { description = "Update the server config."; };
            type = "app";
            program = replaceInBash ./programs/update.sh { inherit fqdn; };
          };
          default = update;
        };
      }
    );
}
