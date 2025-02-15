{ self, lib, perchModules ? [ ], ... }:

let
  actuatePerchModule = perchModule:
    let
      perchModulePathPart =
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
        if builtins.isFunction importedPerchModule
        then
          { ... }@perchModuleInputs:
          (importedPerchModule
            (perchModuleInputs // {
              inherit self;
            }) // perchModulePathPart)
        else
          importedPerchModule //
          perchModulePathPart;
    in
    perchModuleWithSelf;
in
{
  options.flake.perchModules = lib.mkOption {
    type =
      lib.types.listOf
        (lib.types.functionTo
          lib.types.deferredModule);
    default = { };
    description = lib.literalMD ''
      Create a `perchModules` flake output.
    '';
  };

  config.flake.perchModules = perchModules;

  config.flake.lib.modules.eval = { specialArgs, modules }:
    let
      actuatedPerchModules =
        builtins.map
          actuatePerchModule
          modules;

      perchModulesModule = {
        config._module.args = {
          perchModules = actuatedPerchModules;
        };
      };
    in
    lib.evalModules {
      class = "perch";
      inherit specialArgs;
      modules = [ perchModulesModule ] ++ modules;
    };
}
