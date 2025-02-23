{ self, lib, ... }:

{
  flake.lib.module.mapFunctionResult =
    mapping:
    function:
    let
      args = lib.functionArgs function;
      mapped = args: mapping (function args);
    in
    lib.setFunctionArgs mapped args;

  flake.lib.module.mapFunctionArgs =
    mapping:
    function:
    let
      args = lib.functionArgs function;
      mapped = args: function (mapping args);
    in
    lib.setFunctionArgs mapped args;

  flake.lib.module.importIfPath =
    module:
    let
      pathPart =
        if (builtins.isPath module)
          || (builtins.isString module)
        then
          let path = module;
          in { _file = path; key = path; }
        else
          { };

      imported =
        if (builtins.isPath module)
          || (builtins.isString module)
        then
          import module
        else module;
    in
    if lib.isFunction imported
    then
      let function = imported;
      in self.lib.module.mapFunctionResult
        (attrset: attrset // pathPart)
        function
    else
      let attrset = imported;
      in attrset // pathPart;

  flake.lib.module.mapAttrsetImports =
    mapping:
    attrset:
    if attrset ? imports
    then
      attrset // {
        imports =
          builtins.map
            (module: mapping
              (self.lib.module.importIfPath module))
            attrset.imports;
      }
    else
      attrset;
}
