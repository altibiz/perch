{ lib, self, ... }:

let
  patchAttrsetImports =
    args:
    result:
    attrset:
    self.lib3.module.mapAttrsetImports
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
      self.lib3.module.mapFunctionArgs
        args
        (self.lib3.module.mapFunctionResult
          (attrset: result
            (patchAttrsetImports args result attrset))
          function)
    else
      result (patchAttrsetImports args result imported);
in
{
  config.flake.lib3.module.patch =
    args:
    result:
    module:
    patchImported
      args
      result
      (self.lib3.module.importIfPath
        module);
}
