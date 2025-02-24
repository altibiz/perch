{ self, lib, ... }:

{
  flake.lib.flake.make =
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
          self.lib.import.dirToFlatPathAttrs
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
                if input ? perchModules
                then input.perchModules.default
                else null)
              selflessInputList);

      eval = self.lib.module.eval {
        specialArgs = inputs;
        selfModules = prefixedRootModules // selfModules;
        inputModules = inputModulesFromInputs ++ inputModules;
      };
    in
    if eval.config ? flake
    then eval.config.flake
    else { };
}
