{ pkgs, ... }:
{
  # Wraps "replaceVars" just so it returns an executable bash script.
  #
  # All these steps are necessary because flake programs must be simple paths
  # to scripts, and "replaceVars" only returns a derivation that lacks execute
  # permissions.
  #
  # The executable bash that's generated here needs a name that doesn't matter,
  # so I just make it the same as the source file.
  replaceInBash = src: replacements:
    let replacedScriptName = builtins.baseNameOf src; in
    pkgs.lib.pipe replacements [
      (pkgs.replaceVars src)
      builtins.readFile
      (pkgs.writers.writeBash replacedScriptName)
      toString
    ];
  # Makes standard ".well-known" file contents with the input as the response
  # payload.
  #
  # Source: https://nixos.org/manual/nixos/stable/index.html#module-services-matrix-synapse
  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${data}';
  '';
  # Adds the standard SSL attributes to an nginx virtual host
  setSslDefaults = vhost: vhost // {
    forceSSL = true;
    enableACME = true;
  };
  # Returns a location attrset for a reverse proxy at a given port
  rProxy = port: {
    proxyPass = "http://[::1]:${toString port}";
  };
  # Takes a list of desired PostgreSQL usernames and returns a list of 
  # PostgreSQL user attrsets with DB ownership and login enabled by default
  stdPgUsers =
    let
      stdPgUser = username: {
        name = username;
        ensureDBOwnership = true;
        ensureClauses.login = true;
      };
    in
    usernames: map stdPgUser usernames;
}