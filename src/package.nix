{ self
, lib
, nixpkgs
, flake-utils
, config
, specialArgs
, ...
}:

# TODO: figure out how to flatten this out

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
      # FIXME: throws because not called here with right args
      # type = lib.types.functionTo lib.types.package;
      type = lib.types.raw;
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
    pkgs.callPackage
      package.function
      specialArgs;
in
{
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

  # NOTE: this is so that perch modules can ask for pkgs but
  # this will only be evaluated in a
  # lib.evalModules with pkgs context
  config._module.args = {
    pkgs = null;
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
