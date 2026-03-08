{ 
  lib,
  dirMap
} :

{ self
, inputs
, systems ? [ "x86_64-linux" ]   # default if not specified
, hosts ? {}                      # optional – if empty, no nixosConfigurations
, overlays ? []                    # can be list or attrset
, packages ? {}
, apps ? {}
, devShells ? {}
, nixosModules ? {}                # exported as nixosModules
, formatter ? {}                   # per-system formatter (e.g. treefmt)
, checks ? {}                      # per-system checks
, specialArgs ? {}                  # extra args for nixosSystem (if hosts given)
, ...
} : let
  # helper to create an app
  makeApp = program: {
    type = "app";
    program = "${program}";
  };

  # instantiate nixpkgs for a given system
  mkPkgs = system:
    import inputs.nixpkgs {
      inherit system;
      overlays = if builtins.isList overlays then overlays else builtins.attrValues overlays;
      config.allowUnfree = true;
    };

  # build NixOS configurations if hosts are provided
  nixosConfigurations =
    if hosts == {} then {} else
    lib.mapAttrs (hostName: hostConfig:
      let
        system = hostConfig.system or (lib.head systems);
        pkgs = mkPkgs system;
      in
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ hostConfig ];
        specialArgs = {
          inherit self inputs hostName pkgs;
          nixosConfigurations = self.nixosConfigurations;
        } // specialArgs;
      }
    ) hosts;

  # per-system outputs: packages, apps, devShells, formatter, checks
  perSystem = system:
    let
      pkgs = mkPkgs system;
      callPackage = pkgs.newScope { inherit self inputs; };

      # process an app: could be a derivation path or a function returning a path
      mkApp = appDef:
        if builtins.isFunction appDef then
          makeApp (appDef { inherit pkgs system self inputs; })
        else
          makeApp appDef;

      # process a devShell definition
      mkShell = shellDef:
        let
          shellArgs = if builtins.isFunction shellDef then shellDef { inherit pkgs system self inputs; } else shellDef;
          # remove functions that might cause issues with mkShell
          sanitized = builtins.removeAttrs shellArgs [
            "__functor" "__functionArgs" "override" "overrideDerivation"
          ];
        in
        pkgs.mkShell (sanitized // {
          shellHook = ''
            echo "Entering dev shell"
            ${shellArgs.shellHook or ""}
          '';
        });
    in {
      packages = lib.mapAttrs (name: pkg:
        if builtins.isPath pkg || builtins.isFunction pkg then
          callPackage pkg { }
        else
          pkg
      ) packages;

      apps = lib.mapAttrs (name: app: mkApp app) apps;

      devShells = lib.mapAttrs (name: shell: mkShell shell) devShells;

      formatter = if builtins.isFunction formatter then
        formatter { inherit pkgs system self inputs; }
      else
        formatter;

      checks = lib.mapAttrs (name: check:
        if builtins.isFunction check then
          check { inherit pkgs system self inputs; }
        else
          check
      ) checks;
    };

  # merge all outputs
  baseOutputs = {
    inherit nixosConfigurations nixosModules;
  } // (if builtins.isList overlays then { overlays = builtins.listToAttrs (map (o: lib.nameValuePair (o.name or "default") o) overlays); } else { overlays = overlays; });

in
baseOutputs // {
  packages = lib.genAttrs systems (system: (perSystem system).packages);
  apps = lib.genAttrs systems (system: (perSystem system).apps);
  devShells = lib.genAttrs systems (system: (perSystem system).devShells);
  formatter = lib.genAttrs systems (system: (perSystem system).formatter);
  checks = lib.genAttrs systems (system: (perSystem system).checks);
}
