{ self
, lib
, specialArgs
, perchModules
, options
, config
, ...
}:

{
  options.integrate.check =
    self.lib.option.mkIntegrationOption
      config
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
      specialArgs
      perchModules
      options
      config
      "check"
      perchModules.current;
}
