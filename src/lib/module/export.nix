{ lib, self, ... }:

let
  exportPerchModuleAttrsetImports =
    specialArgs:
    attrset:
    self.lib.module.mapAttrsetImports
      (exportImported specialArgs)
      attrset;

  shallowlyExportAttrset =
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
        (builtins.removeAttrs
          config
          [ "flake" "seal" "branch" "integrate" ]);
    in
    if hasConfig
    then
      attrset //
      { config = exportedConfig; }
    else
      exportedConfig;

  exportImported =
    specialArgs:
    imported:
    if lib.isFunction imported
    then
      let
        function = imported;
      in
      self.lib.module.mapFunctionResult
        (attrsets:
        (exportPerchModuleAttrsetImports specialArgs)
          (shallowlyExportAttrset attrsets))
        (self.lib.module.mapFunctionArgs
          (args: args // specialArgs)
          function)
    else
      let
        attrset =
          imported;
      in
      (exportPerchModuleAttrsetImports specialArgs)
        (shallowlyExportAttrset attrset);
in
{
  flake.lib.module.export =
    specialArgs:
    module:
    (exportImported specialArgs)
      (self.lib.module.importIfPath
        module);
}
