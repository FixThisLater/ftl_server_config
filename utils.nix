{ pkgs, ... }:
{
  # Wraps "replaceVars" just so it returns an executable bash script
  replaceInBash = src: replacements:
    let
      replacedCode = builtins.readFile (pkgs.replaceVars src replacements);
    in toString (
      pkgs.writers.writeBash (builtins.baseNameOf src) replacedCode
    );
}