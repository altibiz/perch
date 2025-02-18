{ self, lib, perchModules, ... }:

{
  options.integrate.check =
    self.lib.option.mkIntegrationOption
      "check";

  options.propagate.checks = lib.mkOption {
    type =
      lib.types.attrsOf
        (lib.types.attrsOf
          lib.types.package);
    default = { };
    description = lib.literalMD ''
      Propagated `checks` flake output.
    '';
  };

  config.propagate.checks =
    self.lib.module.artifacts
      "check"
      perchModules.current;
}
