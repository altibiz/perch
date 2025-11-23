{ lib, self, ... }:

let
  exportAttrsetImports =
    specialArgs:
    paths:
    attrset:
    self.lib3.module.mapAttrsetImports
      (exportImported specialArgs paths)
      attrset;

  shallowlyExportAttrset =
    paths:
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

      exportedConfig =
        builtins.foldl'
          (acc: next: self.lib3.attrset.removeAttrByPath next acc)
          config
          paths;
    in
    if hasConfig
    then
      attrset //
      {
        config = exportedConfig;
      }
    else
      exportedConfig;

  exportImported =
    specialArgs:
    paths:
    imported:
    if lib.isFunction imported
    then
      let
        function = imported;
      in
      self.lib3.module.mapFunctionResult
        (attrsets:
        (exportAttrsetImports specialArgs paths)
          (shallowlyExportAttrset paths attrsets))
        (self.lib3.module.mapFunctionArgs
          (args: args // specialArgs)
          function)
    else
      let
        attrset =
          imported;
      in
      (exportAttrsetImports specialArgs paths)
        (shallowlyExportAttrset paths attrset);
in
{
  flake.lib3.module.export =
    specialArgs:
    paths:
    module:
    (exportImported specialArgs paths)
      (self.lib3.module.importIfPath
        module);
}
