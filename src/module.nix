{ self, lib, perchModules ? { }, ... }:

let
  importPerchModule = perchModule:
    if (builtins.isPath perchModule)
      || (builtins.isString perchModule)
    then
      import perchModule
    else perchModule;

  mergePerchModulePath = perchModule:
    let
      perchModulePathPart =
        if (builtins.isPath perchModule)
          || (builtins.isString perchModule)
        then { _file = perchModule; }
        else { };

      importedPerchModule =
        importPerchModule
          perchModule;
    in
    if builtins.isFunction importedPerchModule
    then
      perchModuleInputs:
      (importedPerchModule perchModuleInputs)
      // perchModulePathPart
    else
      importedPerchModule
      // perchModulePathPart;

  exportPerchModuleObjectImports = perchModuleObject:
    if perchModuleObject ? imports
    then
      perchModuleObject // {
        imports = builtins.map
          (imported:
            exportPerchModule
              (mergePerchModulePath imported))
          perchModuleObject.imports;
      }
    else
      perchModuleObject;

  exportPerchModule = importedPerchModule:
    if builtins.isFunction importedPerchModule
    then
      perchModuleInputs:
      let
        importedPerchModuleObject =
          importedPerchModule
            (perchModuleInputs // {
              inherit self;
            });
      in
      exportPerchModuleObjectImports
        importedPerchModuleObject
    else
      importedPerchModule;

  silencePerchModuleObjectImports = perchModuleObject:
    if perchModuleObject ? imports
    then
      perchModuleObject // {
        imports = builtins.map
          (imported:
            silencePerchModule
              (mergePerchModulePath imported));
      }
    else
      perchModuleObject;

  shallowlySilencePerchModuleObject = perchModuleObject:
    let
      hasConfig = perchModuleObject ? config;

      perchModuleConfig =
        if hasConfig
        then perchModuleObject.config
        else perchModuleObject;

      silencedPerchModuleConfig =
        builtins.removeAttrs
          perchModuleConfig
          [ "flake" ];
    in
    if hasConfig
    then
      perchModuleObject //
      { config = silencedPerchModuleConfig; }
    else
      silencedPerchModuleConfig;

  silencePerchModule = importedPerchModule:
    if builtins.isFunction importedPerchModule
    then
      perchModuleInputs:
      silencePerchModuleObjectImports
        (shallowlySilencePerchModuleObject
          (importedPerchModule perchModuleInputs))
    else
      shallowlySilencePerchModuleObject
        importedPerchModule;
in
{
  options.flake.perchModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.deferredModule;
    default = { };
    description = lib.literalMD ''
      Create a `perchModules` flake output.
    '';
  };

  config.flake.perchModules = perchModules;

  config.flake.lib.modules.eval =
    { specialArgs
    , selfModules
    , inputModules ? [ ]
    }:
    let
      exportedPerchModules =
        builtins.mapAttrs
          (_: perchModule:
            exportPerchModule
              (mergePerchModulePath perchModule))
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

      perchModulesModule = {
        config._module.args = {
          perchModules =
            defaultExportedPerchModulePart
            // exportedPerchModules;
        };
      };

      silencedPerchModules =
        builtins.map
          (perchModule:
            silencePerchModule
              (mergePerchModulePath perchModule))
          inputModules;
    in
    lib.evalModules {
      class = "perch";
      inherit specialArgs;
      modules =
        [ perchModulesModule ]
        ++ (builtins.attrValues selfModules)
        ++ silencedPerchModules;
    };
}
