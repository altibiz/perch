{ lib, self, ... }:

let
  propagateAttrsetImports =
    output:
    paths:
    attrset:
    self.lib.module.mapAttrsetImports
      (propagateImported output paths)
      attrset;

  shallowlyPropagateAttrset =
    output:
    paths:
    attrset:
    let
      hasConfig =
        attrset ? config
        || attrset ? options;

      config =
        if attrset ? config
        then attrset.config
        else if attrset ? options
        then { }
        else attrset;

      outputConfig =
        if config ? ${output}
        then config.${output}
        else { };

      propagatedConfig =
        builtins.foldl'
          (acc: next: lib.recursiveUpdate acc next)
          { }
          (builtins.map
            (path:
              if config ? ${path}
              then config.${path}
              else { })
            paths);

      selfPropagatedConfig =
        config // {
          ${output} =
            propagatedConfig
            // outputConfig;
        };
    in
    if hasConfig
    then
      attrset //
      { config = selfPropagatedConfig; }
    else
      selfPropagatedConfig;

  propagateImported =
    output:
    paths:
    imported:
    if lib.isFunction imported
    then
      let
        function = imported;
      in
      self.lib.module.mapFunctionResult
        (attrset:
        propagateAttrsetImports
          output
          paths
          (shallowlyPropagateAttrset
            output
            paths
            attrset))
        function
    else
      propagateAttrsetImports
        output
        paths
        (shallowlyPropagateAttrset
          output
          paths
          imported);
in
{
  config.flake.lib.module.propagate =
    output:
    paths:
    module:
    propagateImported
      output
      paths
      (self.lib.module.importIfPath
        module);
}
