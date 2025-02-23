{ self
, lib
, specialArgs
, perchModules
, options
, config
, ...
}:

{
  options.integrate.package =
    self.lib.option.mkIntegrationOption
      config
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

  options.seal.defaults.package = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = lib.literalMD ''
      The default `packages` flake output.
    '';
  };

  config.propagate.packages =
    let
      default = config.seal.defaults.package;

      artifacts =
        self.lib.module.artifacts
          specialArgs
          perchModules
          options
          config
          "package"
          perchModules.current;
    in
    if default == null
    then artifacts
    else
      builtins.mapAttrs
        (_: system:
          system // {
            default = system.${default};
          })
        artifacts;
}
