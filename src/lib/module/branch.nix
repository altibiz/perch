{ self, lib, ... }:

let
  pruneAttrsetImports =
    specialArgs:
    path:
    attrset:
    self.lib.module.mapAttrsetImports
      (pruneImported specialArgs path)
      attrset;

  shallowlyPruneAttrset =
    path:
    attrset:
    let
      hasConfig =
        attrset ? config
        || attrset ? options;

      actualPath =
        if hasConfig
        then [ "config" ] ++ path
        else path;

      prunedConfig =
        lib.attrByPath
          actualPath
          { }
          attrset;
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
        (attrset:
        (shallowlyPruneAttrset path)
          ((pruneAttrsetImports specialArgs path)
            attrset))
        (self.lib.module.mapFunctionArgs
          (args: args // specialArgs)
          function)
    else
      let
        perchModuleAttrset =
          imported;
      in
      (shallowlyPruneAttrset path)
        ((pruneAttrsetImports specialArgs path)
          perchModuleAttrset);
in
{
  flake.lib.module.prune =
    specialArgs:
    branch:
    module:
    (pruneImported specialArgs [ "branch" branch branch ])
      (self.lib.module.importIfPath
        module);

  flake.lib.module.isolate =
    system:
    integration:
    module:
    (pruneImported { } [ "integrate" system ])
      (self.lib.module.importIfPath
        module);
}
