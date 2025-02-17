{ lib, self, options, config, ... }:

{
  options.flake = {
    perchModules = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = { };
      description = lib.literalMD ''
        Create a `perchModules` flake output.
      '';
    };
  }
  // (builtins.mapAttrs
    (name: option: option // {
      description = lib.literalMD ''
        Create a `${name}` flake output.
      '';
    })
    options.propagate);

  options.integrate.systems = lib.mkOption {
    type =
      lib.types.listOf
        lib.types.str;
    default = config.seal.defaults.systems;
    description = lib.literalMD ''
      List of systems in which to integrate.
    '';
  };

  config.flake.lib.module.eval =
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
        _module.args.trunkArgs = null;
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
