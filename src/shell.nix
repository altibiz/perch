{ self, lib, perchModules, ... }:

{
  options.integrate.devShell =
    self.lib.option.mkIntegrationOption
      "devShell";

  options.propagate.devShells = lib.mkOption {
    type =
      lib.types.attrsOf
        (lib.types.attrsOf
          lib.types.package);
    default = { };
    description = lib.literalMD ''
      Propagated `devShells` flake output.
    '';
  };

  config.propagate.devShells =
    self.lib.module.artifacts
      "devShell"
      perchModules.current;
}
