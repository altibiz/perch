{ lib, self, options, config, ... }:

let
  selfPropagateObjectImports =
    object:
    self.module.mapObjectImports
      selfPropagateImported
      object;

  shallowlySelfPropagateObject =
    object:
    let
      hasConfig =
        object ? config
        || object ? options;

      config =
        if object ? config
        then object.config
        else if object ? options
        then { }
        else object;

      flakeConfig =
        if config ? flake
        then config.flake
        else { };

      propagatedConfig =
        if config ? propagate
        then config.propagate
        else { };

      selfPropagatedConfig =
        config // {
          flake =
            propagatedConfig
            // flakeConfig;
        };
    in
    if hasConfig
    then
      object //
      { config = selfPropagatedConfig; }
    else
      selfPropagatedConfig;

  selfPropagateImported =
    imported:
    if lib.isFunction imported
    then
      let
        function = imported;
      in
      self.lib.module.mapFunctionResult
        (object:
        selfPropagateObjectImports
          (shallowlySelfPropagateObject
            object))
        function
    else
      selfPropagateObjectImports
        (shallowlySelfPropagateObject
          imported);
in
{
  options.flake = {
    perchModules = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = { };
      description = lib.literalMD ''
        Create a `perchModules` flake output.
      '';
    };
  }
  // (builtins.mapAttrs
    (name: option: option // {
      description = lib.literalMD ''
        Create a `${name}` flake output.
      '';
    })
    options.propagate);

  options.integrate.systems = lib.mkOption {
    type =
      lib.types.listOf
        lib.types.str;
    default = config.seal.defaults.systems;
    description = lib.literalMD ''
      List of systems in which to integrate.
    '';
  };

  config.flake.lib.module.selfPropagate =
    module:
    selfPropagateImported
      (self.lib.module.importIfPath
        module);
}
