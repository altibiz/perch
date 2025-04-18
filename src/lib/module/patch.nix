{ lib, self, ... }:

let
  patchAttrsetImports =
    args:
    result:
    attrset:
    self.lib.module.mapAttrsetImports
      (patchImported args result)
      attrset;

  patchImported =
    args:
    result:
    imported:
    if lib.isFunction imported
    then
      let
        function = imported;
      in
      self.lib.module.mapFunctionArgs
        args
        (self.lib.module.mapFunctionResult
          (attrset: result
            (patchAttrsetImports args result attrset))
          function)
    else
      result (patchAttrsetImports args result imported);
in
{
  config.flake.lib.module.patch =
    args:
    result:
    module:
    patchImported
      args
      result
      (self.lib.module.importIfPath
        module);
}
