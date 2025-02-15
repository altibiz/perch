{ self, lib, perchModules ? [ ], ... }:

{
  options.flake.perchModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = lib.literalMD ''
      Create a `perchModules` flake output.
    '';
  };

  config.flake.perchModules =
    builtins.map
      (perchModule:
        let
          perchModulePath =
            if (builtins.isPath perchModule)
              || (builtins.isString perchModule)
            then { _file = perchModule; }
            else { };

          importedPerchModule =
            if (builtins.isPath perchModule)
              || (builtins.isString perchModule)
            then
              import perchModule
            else perchModule;

          perchModuleWithSelf =
            if (builtins.isFunction importedPerchModule)
            then
              { ... }@perchModuleInputs:
              importedPerchModule
                (perchModuleInputs // {
                  inherit self;
                })
            else importedPerchModule;
        in
        perchModuleWithSelf)
      perchModules;
  config.flake.lib.modules.eval = { specialArgs, modules }:
    let
      internalModule = {
        config._module.args = {
          perchModules = modules;
        };
      };
    in
    lib.evalModules {
      class = "perch";
      inherit specialArgs;
      modules = [ internalModule ] ++ modules;
    };
}
