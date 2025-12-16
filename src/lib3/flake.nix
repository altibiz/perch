{ self, lib, ... }:

{
  flake.lib3.flake.make =
    { inputs
    , root ? null
    , prefix ? null
    , selfModules ? { }
    , inputModules ? [ ]
    , includeInputModulesFromInputs ? true
    }:
    let
      prefixedRoot =
        if root == null || prefix == null then null
        else lib.path.append root prefix;

      prefixedRootModules =
        if prefixedRoot == null then { }
        else
          self.lib3.import.dirToFlatPathAttrs
            prefixedRoot;

      inputModulesFromInputs =
        if !includeInputModulesFromInputs then [ ]
        else
          let
            selflessInputList =
              builtins.attrValues
                (builtins.removeAttrs
                  inputs
                  [ "self" ]);
          in
          builtins.filter
            (module: module != null)
            (builtins.map
              (input:
                if input ? modules
                then input.modules.default
                else null)
              selflessInputList);

      eval = self.lib3.eval.flake
        (inputs // { inherit root; })
        (inputModulesFromInputs ++ inputModules)
        (prefixedRootModules // selfModules);
    in
    if eval.config ? flake
    then eval.config.flake
    else { };
}
