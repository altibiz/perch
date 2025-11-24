{ lib, self, ... }:

let
  patchAttrsetImports =
    mapArgsDeclaration:
    mapArgsDefinition:
    mapResult:
    attrset:
    self.lib3.trivial.mapAttrsetImports
      (patchImported
        mapArgsDeclaration
        mapArgsDefinition
        mapResult)
      attrset;

  patchImported =
    mapArgsDeclaration:
    mapArgsDefinition:
    mapResult:
    imported:
    if lib.isFunction imported
    then
      let
        function = imported;
      in
      self.lib3.trivial.mapFunctionArgs
        mapArgsDeclaration
        mapArgsDefinition
        (self.lib3.trivial.mapFunctionResult
          (function: attrset: mapResult
            function
            (patchAttrsetImports
              mapArgsDeclaration
              mapArgsDefinition
              mapResult
              attrset))
          function)
    else
      mapResult
        imported
        (patchAttrsetImports
          mapArgsDeclaration
          mapArgsDefinition
          mapResult
          imported);
in
{
  flake.lib3.module.patch =
    mapArgsDeclaration:
    mapArgsDefinition:
    mapResult:
    module:
    patchImported
      mapArgsDeclaration
      mapArgsDefinition
      mapResult
      (self.lib3.trivial.importIfPath
        module);
}
