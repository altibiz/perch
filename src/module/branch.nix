{ self
, lib
, specialArgs
, ...
}:

let
  pruneObjectImports =
    path:
    object:
    self.lib.module.mapObjectImports
      (pruneImported
        path)
      object;

  shallowlyPruneObject =
    path:
    object:
    let
      hasConfig =
        object ? config
        || object ? options;

      configPath =
        if hasConfig
        then [ "config" ] ++ path
        else path;

      prunedConfig =
        lib.attrByPath
          configPath
          null
          object;
    in
    prunedConfig;

  pruneImported =
    path:
    imported:
    if lib.isFunction imported
    then
      let
        function = imported;
      in
      self.lib.module.mapFunctionResult
        (object:
        (pruneObjectImports path)
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
      (pruneObjectImports path)
        ((shallowlyPruneObject path)
          perchModuleObject);
in
{
  flake.lib.module.prune =
    branch:
    module:
    (pruneImported [ "branch" branch ])
      (self.lib.module.importIfPath
        module);

  flake.lib.module.isolate =
    integration:
    system:
    module:
    (pruneImported [ "integrate" system integration ])
      (self.lib.module.importIfPath
        module);
}
