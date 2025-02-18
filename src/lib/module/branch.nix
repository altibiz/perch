{ self, lib, ... }:

let
  pruneObjectImports =
    specialArgs:
    path:
    object:
    self.lib.module.mapObjectImports
      (pruneImported specialArgs path)
      object;

  shallowlyPruneObject =
    path:
    object:
    let
      hasConfig =
        object ? config
        || object ? options;

      actualPath =
        if hasConfig
        then [ "config" ] ++ path
        else path;

      prunedConfig =
        lib.attrByPath
          actualPath
          { }
          object;
    in
    prunedConfig;

  pruneImported =
    specialArgs:
    path:
    imported:
    if lib.isFunction imported
    then
      let
        function = imported;
      in
      self.lib.module.mapFunctionResult
        (object:
        (pruneObjectImports specialArgs path)
          ((shallowlyPruneObject path)
            object))
        (self.lib.module.mapFunctionArgs
          (args: args // specialArgs)
          function)
    else
      let
        perchModuleObject =
          imported;
      in
      (pruneObjectImports specialArgs path)
        ((shallowlyPruneObject path)
          perchModuleObject);
in
{
  flake.lib.module.prune =
    specialArgs:
    branch:
    module:
    (pruneImported specialArgs [ "branch" branch ])
      (self.lib.module.importIfPath
        module);

  flake.lib.module.isolate =
    system:
    integration:
    module:
    (pruneImported { } [ "integrate" system integration ])
      (self.lib.module.importIfPath
        module);
}
