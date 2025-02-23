# Trivial

- `module.mapFunctionResult` (`(? -> ?) -> (? -> ?) -> (? -> ?)`): Maps the
  function result while preserving the `__functionArgs` of the original
  function.

- `module.mapFunctionArgs` (`(? -> ?) -> (? -> ?) -> (? -> ?)`): Maps the
  function arguments while preservice the `__functionArgs` of the original
  function.

- `module.importIfPath` (`module -> imported module`): Imports a module and sets
  the `_file` and `key` attributes if it is a path

- `module.mapAttrsetImports`
  (`(module -> module) -> attrset module -> attrset module`): Maps the imported
  modules of an attrset module.
