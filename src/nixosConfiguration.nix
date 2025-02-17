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
    builtins.listToAttrs
      (lib.flatten
        (lib.mapAttrsToList
          (system: configurations:
            lib.mapAttrsToList
              (name: configuration: {
                name = "${name}-${system}";
                value = configuration;
              })
              configurations)
          (self.lib.module.integration.artifacts
            "nixosConfiguration"
            perchModules.current)));
}
