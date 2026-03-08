{
  description = "tinyFlake: a tiny flake utility";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      dirMap = import ./dirMap.nix { inherit lib; };
      mkFlake = import ./mkFlake.nix { inherit lib dirMap; };     
    in {
      lib = dirMap // { inherit tinyFlake; };

    };}
