{ lib, self, ... }:

let
  exportPerchModuleObjectImports =
    specialArgs:
    object:
    self.lib.module.mapObjectImports
      (exportImported specialArgs)
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
    specialArgs:
    imported:
    if lib.isFunction imported
    then
      let
        function = imported;
      in
      self.lib.module.mapFunctionResult
        (objects:
        (exportPerchModuleObjectImports specialArgs)
          (shallowlyExportObject objects))
        (self.lib.module.mapFunctionArgs
          (args: args // specialArgs)
          function)
    else
      let
        object =
          imported;
      in
      (exportPerchModuleObjectImports specialArgs)
        (shallowlyExportObject object);
in
{
  flake.lib.module.export =
    specialArgs:
    module:
    (exportImported specialArgs)
      (self.lib.module.importIfPath
        module);
}
