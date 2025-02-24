{ lib, self, ... }:

let
  deriveAttrsetImports =
    attrset:
    self.lib.module.mapAttrsetImports
      deriveImported
      attrset;

  shallowlyDeriveAttrset =
    attrset:
    let
      hasConfig =
        attrset ? config
        || attrset ? options;

      config =
        if attrset ? config
        then attrset.config
        else if attrset ? options
        then { }
        else attrset;

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
      attrset //
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
        (attrset:
        deriveAttrsetImports
          (shallowlyDeriveAttrset
            attrset))
        function
    else
      deriveAttrsetImports
        (shallowlyDeriveAttrset
          imported);
in
{
  flake.lib.module.derive =
    module:
    deriveImported
      (self.lib.module.importIfPath
        module);
}
