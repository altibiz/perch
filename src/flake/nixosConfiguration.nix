{ self, lib, perchModules, ... }:

{
  options.integrate.nixosConfiguration =
    self.lib.option.mkIntegrationOption
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
      "nixosConfiguration"
      perchModules.current;
}
