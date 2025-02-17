{ self
, lib
, specialArgs
, ...
}@trunkArgs:

let
  pruneObjectImports =
    branch:
    object:
    self.lib.module.mapObjectImports
      (pruneImported
        branch)
      object;

  shallowlyPruneObject =
    branch:
    object:
    let
      config =
        if object ? config
        then object.config
        else if object ? options
        then { }
        else object;

      branches =
        if config ? branch
        then config.branch
        else { };

      prunedConfig =
        if branches ? ${branch}
        then branches.${branch}
        else null;
    in
    prunedConfig;

  pruneImported =
    branch:
    imported:
    if lib.isFunction imported
    then
      let
        function = imported;
      in
      self.lib.module.mapFunctionResult
        (perchModuleObject:
        (pruneObjectImports branch)
          ((shallowlyPruneObject branch)
            perchModuleObject))
        (self.lib.module.mapFunctionArgs
          (perchModuleFunctionArgs:
          perchModuleFunctionArgs
          // specialArgs
          // {
            inherit trunkArgs;
          })
          function)
    else
      let
        perchModuleObject =
          imported;
      in
      (pruneObjectImports branch)
        ((shallowlyPruneObject branch)
          perchModuleObject);
in
{
  flake.lib.module.prune =
    branch:
    module:
    (pruneImported branch)
      (self.lib.module.importIfPath
        module);
}
