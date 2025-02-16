{ self, lib, ... }:

let
  importPerchModule =
    perchModule:
    if (builtins.isPath perchModule)
      || (builtins.isString perchModule)
    then
      import perchModule
    else perchModule;

  importAndMergePerchModulePath =
    perchModule:
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
    mapping:
    perchModuleObject:
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
      exportImportedPerchModule
      perchModuleObject;

  exportImportedPerchModule =
    importedPerchModule:
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

  silencePerchModuleObjectImports =
    perchModuleObject:
    mapPerchModuleObjectImports
      silenceImportedPerchModule
      perchModuleObject;

  shallowlySilencePerchModuleObject =
    perchModuleObject:
    let
      hasConfig =
        perchModuleObject ? config;

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

  silenceImportedPerchModule =
    importedPerchModule:
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

  prunePerchModuleObjectImports =
    prefix:
    perchModuleObject:
    mapPerchModuleObjectImports
      (pruneImportedPerchModule
        prefix)
      perchModuleObject;

  shallowlyPrunePerchModuleObject =
    prefix:
    perchModuleObject:
    let
      hasPruning =
        perchModuleObject ? prune;

      pruningPerchModuleObject =
        if hasPruning
        then perchModuleObject.prune
        else { };

      hasPrefix =
        pruningPerchModuleObject ? ${prefix};

      prunedPerchModuleObject =
        if hasPrefix
        then pruningPerchModuleObject.${prefix}
        else { };
    in
    prunedPerchModuleObject;

  pruneImportedPerchModule =
    prefix:
    importedPerchModule:
    if builtins.isFunction importedPerchModule
    then
      perchModuleInputs:
      (prunePerchModuleObjectImports prefix)
        ((shallowlyPrunePerchModuleObject prefix)
          (importedPerchModule perchModuleInputs))
    else
      (prunePerchModuleObjectImports prefix)
        ((shallowlyPrunePerchModuleObject prefix)
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

  options.prune = lib.mkOption {
    type = lib.types.raw;
    default = { };
    description = lib.literalMD ''
      Register objects to be pruned by other modules.
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

      allExportedPerchModules =
        defaultExportedPerchModulePart
        // exportedPerchModules;

      silencedPerchModules =
        builtins.map
          (perchModule:
            silenceImportedPerchModule
              (importAndMergePerchModulePath
                perchModule))
          inputModules;

      allPerchModules =
        (builtins.attrValues selfModules)
        ++ silencedPerchModules;

      perchModulesModule = {
        _module.args = {
          selfPerchModules =
            allExportedPerchModules;
          inputPerchModules =
            silencedPerchModules;
          allPerchModules =
            allPerchModules;
        };
        flake.perchModules =
          allExportedPerchModules;
      };
    in
    lib.evalModules {
      class = "perch";
      inherit specialArgs;
      modules =
        [ perchModulesModule ]
        ++ (builtins.attrValues selfModules)
        ++ silencedPerchModules;
    };

  config.flake.lib.module.export = perchModule:
    exportImportedPerchModule
      (importAndMergePerchModulePath
        perchModule);

  config.flake.lib.module.silence = perchModule:
    silenceImportedPerchModule
      (importAndMergePerchModulePath
        perchModule);

  config.flake.lib.module.prune = prefix: perchModule:
    (pruneImportedPerchModule prefix)
      (importAndMergePerchModulePath
        perchModule);
}
