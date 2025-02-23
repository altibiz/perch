{ self
, lib
, specialArgs
, perchModules
, options
, config
, ...
}:

let
  appSubmodule = {
    options.type = lib.mkOption {
      type = lib.types.strMatching "app";
      default = "app";
      description = lib.literalMD ''
        App type.
      '';
    };

    options.program = lib.mkOption {
      type = lib.types.package;
      description = lib.literalMD ''
        App program.
      '';
    };
  };
in
{
  options.integrate.app =
    self.lib.option.mkIntegrationOption
      config
      "app";

  options.propagate.apps = lib.mkOption {
    type =
      lib.types.attrsOf
        (lib.types.attrsOf
          (lib.types.submodule
            appSubmodule));
    default = { };
    description = lib.literalMD ''
      Propagated `apps` flake output.
    '';
  };

  options.seal.defaults.packagesAsApps = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = lib.literalMD ''
      Convert all packages to apps.
    '';
  };

  options.seal.defaults.app = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = lib.literalMD ''
      The default `apps` flake output.
    '';
  };

  config.propagate.apps =
    let
      default = config.seal.defaults.app;

      artifacts =
        self.lib.module.artifacts
          specialArgs
          perchModules
          options
          config
          "app"
          perchModules.current;

      finalArtifacts =
        if config.seal.defaults.packagesAsApps
        then
          lib.attrsets.recursiveUpdateUntil
            (path: _: _:
              (builtins.length path)
              == 2)
            artifacts
            config.flake.packages
        else artifacts;
    in
    builtins.mapAttrs
      (_: system:
        let
          finalSystem =
            builtins.mapAttrs
              (_: artifact: {
                type = "app";
                program = artifact;
              })
              system;
        in
        if
          default != null
        then
          finalSystem // {
            default = finalSystem.${default};
          }
        else
          finalSystem)
      finalArtifacts;
}
