{ self, lib, perchModules, config, ... }:

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

  options.seal.defaults.devShell = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = lib.literalMD ''
      The default `devShells` flake output.
    '';
  };

  config.propagate.devShells =
    let
      default = config.seal.defaults.devShell;
      artifacts =
        self.lib.module.artifacts
          "devShell"
          perchModules.current;
    in
    if default == null
    then artifacts
    else
      builtins.mapAttrs
        (_: system:
          if system ? ${default}
          then
            system // {
              default = system.${default};
            }
          else
            system)
        artifacts;
}
