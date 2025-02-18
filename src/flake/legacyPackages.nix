{ self, lib, perchModules, config, ... }:

{
  options.integrate.legacyPackage =
    self.lib.option.mkIntegrationOption
      "legacyPackage";

  options.propagate.legacyPackages = lib.mkOption {
    type =
      lib.types.attrsOf
        (lib.types.attrsOf
          lib.types.package);
    default = { };
    description = lib.literalMD ''
      Propagated `legacyPackages` flake output.
    '';
  };

  options.seal.defaults.packagesAsLegacyPackages = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = lib.literalMD ''
      Convert all packages to legacy packages except the default.
    '';
  };

  config.propagate.legacyPackages =
    let
      artifacts =
        self.lib.module.artifacts
          "legacyPackage"
          perchModules.current;

      finalArtifacts =
        if config.seal.defaults.packagesAsLegacyPackages
        then
          lib.attrsets.recursiveUpdateUntil
            (path: _: _:
              (builtins.length path)
              == 2)
            artifacts
            (builtins.mapAttrs
              (_: system:
                lib.filterAttrs
                  (name: _: name != "default")
                  system)
              config.flake.packages)
        else artifacts;
    in
    finalArtifacts;
}
