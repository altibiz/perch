{ lib, self, ... }:

{
  flake.lib.module.eval =
    { specialArgs
    , selfModules
    , inputModules ? [ ]
    }:
    let
      exportedPerchModules =
        builtins.mapAttrs
          (_: self.lib.module.export)
          selfModules;

      exportedPerchModuleList =
        builtins.attrValues
          exportedPerchModules;

      defaultExportedPerchModulePart =
        if (builtins.length exportedPerchModuleList) == 0
        then { }
        else {
          default = {
            _file = ./modules.nix;
            imports = exportedPerchModuleList;
          };
        };

      allExportedPerchModules =
        defaultExportedPerchModulePart
        // exportedPerchModules;

      derivedPerchModules =
        builtins.map
          self.lib.module.derive
          inputModules;

      selfPropagatedModules =
        builtins.mapAttrs
          (_: self.lib.module.selfPropagate)
          selfModules;

      allPerchModules =
        (builtins.attrValues
          selfPropagatedModules)
        ++ derivedPerchModules;

      perchModulesModule = {
        _module.args.perchModules = {
          current =
            selfPropagatedModules;
          derived =
            derivedPerchModules;
          all =
            allPerchModules;
        };
      };

      flakePerchModulesModule = {
        flake.perchModules =
          allExportedPerchModules;
      };

      fakeArgsModule = {
        _module.args.pkgs = null;
        _module.args.super = null;
      };
    in
    lib.evalModules {
      class = "perch";
      inherit specialArgs;
      modules = [
        perchModulesModule
        flakePerchModulesModule
        fakeArgsModule
      ] ++ allPerchModules;
    };
}
