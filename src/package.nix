{ self, lib, nixpkgs, flake-utils, config, ... }:

let
  packageSubmodule = {
    options.systems = lib.mkOption {
      type =
        lib.types.listOf
          lib.types.str;
      default =
        flake-utils.lib.defaultSystems;
      description = lib.literalMD ''
        Systems for which to build the package.
      '';
    };

    options.function = lib.mkOption {
      type =
        lib.types.functionTo
          lib.types.package;
      description = lib.literalMD ''
        Package function which will be called with `pkgs.callPackage`.
      '';
    };

    options.nixpkgs.config = lib.mkOption {
      type = self.lib.type.nixpkgs.config;
      default = config.seal.defaults.nixpkgs.config;
      description = lib.literalMD ''
        Config to pass to nixpkgs when creating `pkgs`.
      '';
    };

    options.nixpkgs.overlays = lib.mkOption {
      type = lib.types.listOf self.lib.type.overlay;
      default = [ config.flake.overlays.default ];
      description = lib.literalMD ''
        Overlays to pass to nixpkgs when creating `pkgs`.
      '';
    };
  };

  systems =
    lib.unique
      (lib.flatten
        (builtins.map
          (package: package.systems)
          (builtins.attrValues
            config.seal.packages)));

  packagesForSystem = system:
    builtins.filter
      ({ package, ... }:
        builtins.elem
          system
          package.systems)
      (lib.mapAttrsToList
        (name: package: { inherit name package; })
        config.seal.packages);

  callPackage = system: package:
    let
      pkgs =
        import nixpkgs {
          inherit system;
          config = package.nixpkgs.config;
          overlays = package.nixpkgs.overlays;
        };
    in
    pkgs.callPackage package.function;
in
{
  options.flake.packages = lib.mkOption {
    type =
      lib.types.attrsOf
        (lib.types.attrsOf
          lib.types.package);
    default = { };
    description = lib.literalMD ''
      Create a `packages` flake output.
    '';
  };

  options.seal.packages = lib.mkOption {
    type =
      lib.types.attrsOf
        (lib.types.submodule
          packageSubmodule);
    default = { };
    description = lib.literalMD ''
      Sealed `packages` flake output configuration.
    '';
  };

  options.propagate.packages = lib.mkOption {
    type =
      lib.types.attrsOf
        (lib.types.attrsOf
          lib.types.package);
    default = { };
    description = lib.literalMD ''
      Propeagated `packages` flake output.
    '';
  };

  config.propagate.packages =
    builtins.listToAttrs
      (builtins.map
        (system:
          {
            name = system;
            value =
              builtins.listToAttrs
                (builtins.map
                  ({ name, package }:
                    {
                      inherit name;
                      value =
                        callPackage
                          system
                          package;
                    })
                  (packagesForSystem
                    system));
          })
        systems);
}
