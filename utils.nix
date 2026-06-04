{ pkgs, ... }:
  # Wraps "replaceVars" just so it returns an executable bash script
  # All these steps are necessary because flake programs must be simple paths
  # to scripts, and "replaceVars" only returns a derivation that lacks execute
  # permissions.
  #
  # The executable bash that's generated here needs a name that doesn't matter,
  # so I just make it the same as the source file.
{ replaceInBash = src: replacements:
  let replacedScriptName = builtins.baseNameOf src; in
  pkgs.lib.pipe replacements [
    (pkgs.replaceVars src)
    builtins.readFile
    (pkgs.writers.writeBash replacedScriptName)
    toString
  ];
}