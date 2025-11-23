{ self, lib, ... }:

let
  pruneAttrsetImports =
    specialArgs:
    path:
    attrset:
    self.lib3.module.mapAttrsetImports
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
      self.lib3.module.mapFunctionResult
        (attrset:
        (shallowlyPruneAttrset path)
          ((pruneAttrsetImports specialArgs path)
            attrset))
        (self.lib3.module.mapFunctionArgs
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
  flake.lib3.module.prune =
    specialArgs:
    path:
    module:
    (pruneImported specialArgs path)
      (self.lib3.module.importIfPath
        module);

  flake.lib3.module.isolate =
    path:
    module:
    (pruneImported { } path)
      (self.lib3.module.importIfPath
        module);
}
