# **tinyFlake**

A tiny flake utility for simplicity.  

  
## **Quick Start!**


Add tinyFlake as an input in your flake.nix:

```nix
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    tinyFlake.url = "github:quackhack-mcblindy/tinyFlake";
  };
```

  
## **Example Usage**  


```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    tinyFlake.url = "github:quackhack-mcblindy/tinyFlake";
  };

  outputs = { self, nixpkgs, tinyFlake, ... }@inputs:
    tinyFlake.lib.makeFlake {
      inherit self inputs;
      systems = [ "x86_64-linux" "aarch64-linux" ];

      # Map your hosts directory – each subdirectory becomes a NixOS config
      hosts = tinyFlake.lib.mapHosts ./hosts;

      # Map overlay files
      overlays = tinyFlake.lib.mapOverlays ./overlays { inherit self inputs; };

      # Map package files (each .nix file becomes a package)
      packages = tinyFlake.lib.mapModules ./packages import;

      # Map devShell files
      devShells = tinyFlake.lib.mapModules ./devShells (path: import path);

      # Map app files (optional)
      apps = tinyFlake.lib.mapModules ./apps (path: import path);

      # Extra modules to include in every NixOS configuration
      modules = [ ];

      # Extra arguments to pass to nixosSystem
      specialArgs = { };
    };
}
```


