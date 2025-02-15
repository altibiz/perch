{ self, lib, ... }:

let
  importPerchModule = perchModule:
    if (builtins.isPath perchModule)
      || (builtins.isString perchModule)
    then
      import perchModule
    else perchModule;

  importAndMergePerchModulePath = perchModule:
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

  mapPerchModuleObjectImports =
    perchModuleObject: mapping:
    if perchModuleObject ? imports
    then
      perchModuleObject // {
        imports = builtins.map
          (module: mapping
            (importAndMergePerchModulePath module))
          perchModuleObject.imports;
      }
    else
      perchModuleObject;

  exportPerchModuleObjectImports = perchModuleObject:
    mapPerchModuleObjectImports
      perchModuleObject
      exportImportedPerchModule;

  exportImportedPerchModule = importedPerchModule:
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
      exportPerchModuleObjectImports
        importedPerchModule;

  silencePerchModuleObjectImports = perchModuleObject:
    mapPerchModuleObjectImports
      perchModuleObject
      silenceImportedPerchModule;

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

  silenceImportedPerchModule = importedPerchModule:
    if builtins.isFunction importedPerchModule
    then
      perchModuleInputs:
      silencePerchModuleObjectImports
        (shallowlySilencePerchModuleObject
          (importedPerchModule perchModuleInputs))
    else
      silencePerchModuleObjectImports
        (shallowlySilencePerchModuleObject
          importedPerchModule);
in
{
  options.flake.perchModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.deferredModule;
    default = { };
    description = lib.literalMD ''
      Create a `perchModules` flake output.
    '';
  };

  config.flake.lib.modules.eval =
    { specialArgs
    , selfModules
    , inputModules ? [ ]
    }:
    let
      exportedPerchModules =
        builtins.mapAttrs
          (_: perchModule:
            exportImportedPerchModule
              (importAndMergePerchModulePath
                perchModule))
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

        config.flake.perchModules =
          defaultExportedPerchModulePart
          // exportedPerchModules;
      };

      silencedPerchModules =
        builtins.map
          (perchModule:
            silenceImportedPerchModule
              (importAndMergePerchModulePath perchModule))
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
