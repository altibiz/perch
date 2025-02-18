{ self, lib, perchModules, ... }:

{
  options.integrate.package =
    self.lib.option.mkIntegrationOption
      "package";

  options.propagate.packages = lib.mkOption {
    type =
      lib.types.attrsOf
        (lib.types.attrsOf
          lib.types.package);
    default = { };
    description = lib.literalMD ''
      Propagated `packages` flake output.
    '';
  };

  config.propagate.packages =
    self.lib.module.artifacts
      "package"
      perchModules.current;
}
