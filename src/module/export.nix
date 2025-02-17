{ lib, self, specialArgs, ... }:

let
  exportPerchModuleObjectImports =
    object:
    self.lib.module.mapObjectImports
      exportImported
      object;

  shallowlyExportObject =
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

      exportedConfig =
        (builtins.removeAttrs
          config
          [ "flake" "seal" "branch" "integrate" ]);
    in
    if hasConfig
    then
      object //
      { config = exportedConfig; }
    else
      exportedConfig;

  exportImported =
    imported:
    if lib.isFunction imported
    then
      let
        function = imported;
      in
      self.lib.module.mapFunctionResult
        (objects:
        exportPerchModuleObjectImports
          (shallowlyExportObject
            objects))
        (self.lib.module.mapFunctionArgs
          (args:
          args
          // specialArgs)
          function)
    else
      let
        object =
          imported;
      in
      exportPerchModuleObjectImports
        (shallowlyExportObject
          object);
in
{
  flake.lib.module.export =
    module:
    exportImported
      (self.lib.module.importIfPath
        module);
}
