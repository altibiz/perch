{ self
, lib
, specialArgs
, perchModules
, options
, config
, ...
}:

{
  options.integrate.nixosConfiguration =
    self.lib.option.mkIntegrationOption
      config
      "nixosConfiguration";

  options.propagate.nixosConfigurations = lib.mkOption {
    type = lib.types.attrsOf lib.types.raw;
    default = { };
    description = lib.literalMD ''
      Propagated `nixosConfigurations` flake output.
    '';
  };

  config.propagate.nixosConfigurations =
    self.lib.module.systems
      specialArgs
      perchModules
      options
      config
      "nixosConfiguration"
      perchModules.current;
}
