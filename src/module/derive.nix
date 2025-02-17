{ lib, self, ... }:

let
  deriveObjectImports =
    object:
    self.lib.module.mapObjectImports
      deriveImported
      object;

  shallowlyDeriveObject =
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

      derivedConfig =
        (builtins.removeAttrs
          config
          [ "flake" "seal" "branch" "integrate" ]) // {
          flake =
            if config ? propagate
            then config.propagate
            else { };
        };
    in
    if hasConfig
    then
      object //
      { config = derivedConfig; }
    else
      derivedConfig;

  deriveImported =
    imported:
    if lib.isFunction imported
    then
      let
        function = imported;
      in
      self.lib.module.mapFunctionResult
        (object:
        deriveObjectImports
          (shallowlyDeriveObject
            object))
        function
    else
      deriveObjectImports
        (shallowlyDeriveObject
          imported);
in
{
  flake.lib.module.derive =
    module:
    deriveImported
      (self.lib.module.importIfPath
        module);
}
