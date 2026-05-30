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
        # Wraps "replaceVars" just so it returns an executable bash script
        replaceInBash = src: replacements:
          let
            replacedCode = builtins.readFile (pkgs.replaceVars src replacements);
          in
          toString (pkgs.writers.writeBash (builtins.baseNameOf src) replacedCode);
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
