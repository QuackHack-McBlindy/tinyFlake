{ lib }:
{
  # Map all subdirectories of `dir` to their imported default.nix
  mapHosts = dir:
    lib.mapAttrs' (name: _:
      lib.nameValuePair name (import (dir + "/${name}"))
    ) (lib.filterAttrs (n: t: t == "directory") (builtins.readDir dir));

  # Map all .nix files in `dir` by applying `fn` to each file's path
  mapModules = dir: fn:
    lib.mapAttrs'
      (name: _: lib.nameValuePair (lib.removeSuffix ".nix" name) (fn (dir + "/${name}")))
      (lib.filterAttrs (n: _: lib.hasSuffix ".nix" n) (builtins.readDir dir));

  # Map all .nix overlay files in `dir` to a list of overlay functions
  mapOverlays = dir: args:
    lib.mapAttrsToList
      (name: _: import (dir + "/${name}") args)
      (lib.filterAttrs (name: type: lib.hasSuffix ".nix" name) (builtins.readDir dir));
}
