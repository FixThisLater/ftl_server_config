# FTL Server Config

Configuration of the server hosting fixthislater.com.

Being a NixOS server, the code in this repo contains everything that constitutes the core of the system, namely in configuration.nix and disk-config.nix. The flake contains those files defined together as a NixOS configuration, and its apps contain the commands that are run to initialize & update the server.

The initialization, in the "create" app, is performed using [nixos-anywhere](https://github.com/nix-community/nixos-anywhere), following the initial creation of the server as an HCloud VM (see the [hcloud](https://github.com/FixThisLater/ftl_hcloud_config) repo). The "update" app uses a simple "nixos-rebuild", drawing on the local files but with the server as the destination of the system updates. Any changes to the config files are reflected on the server following an execution of `nix run .#update`.

All of this relies on SSH, which is implicit & assumed - the system running the flake must have an SSH agent with a key added granting root access to the server. In the server's config itself, there's the public key corresponding to a private key, to be used for updates; for the initial creation, however, you need the separate key that HCloud granted access to when it created the server, and, after the initialization, that key is non-functional.