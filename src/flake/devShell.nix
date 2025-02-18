{ self
, lib
, specialArgs
, perchModules
, options
, config
, ...
}:

{
  options.integrate.devShell =
    self.lib.option.mkIntegrationOption
      config
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
          specialArgs
          perchModules
          options
          config
          "devShell"
          perchModules.current;
    in
    if
      default == null
    then
      artifacts
    else
      builtins.mapAttrs
        (_: system:
          system // {
            default = system.${default};
          })
        artifacts;
}
