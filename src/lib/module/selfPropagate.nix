{ lib, self, ... }:

# TODO: merging propagated with flake

let
  selfPropagateObjectImports =
    object:
    self.lib.module.mapObjectImports
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
  config.flake.lib.module.selfPropagate =
    module:
    selfPropagateImported
      (self.lib.module.importIfPath
        module);
}
