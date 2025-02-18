{ self, lib, perchModules, config, ... }:

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

  config.propagate.apps =
    let
      artifacts =
        self.lib.module.artifacts
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
        builtins.mapAttrs
          (_: artifact: {
            type = "app";
            program = artifact;
          })
          system)
      finalArtifacts;
}
