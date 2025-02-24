{ lib, self, ... }:

# TODO: merging propagated with flake

let
  selfPropagateAttrsetImports =
    attrset:
    self.lib.module.mapAttrsetImports
      selfPropagateImported
      attrset;

  shallowlySelfPropagateAttrset =
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
      attrset //
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
        (attrset:
        selfPropagateAttrsetImports
          (shallowlySelfPropagateAttrset
            attrset))
        function
    else
      selfPropagateAttrsetImports
        (shallowlySelfPropagateAttrset
          imported);
in
{
  config.flake.lib.module.selfPropagate =
    module:
    selfPropagateImported
      (self.lib.module.importIfPath
        module);
}
