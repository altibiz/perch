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
      let
        perchModuleObject =
          importedPerchModule
            perchModuleInputs;
      in
      perchModuleObject
      // perchModulePathPart
    else
      let
        perchModuleObject =
          importedPerchModule;
      in
      perchModuleObject
      // perchModulePathPart;

  mapImportedPerchModuleObjectImports =
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

  selfPropagatePerchModuleObjectImports = perchModuleObject:
    mapImportedPerchModuleObjectImports
      selfPropagateImportedPerchModule
      perchModuleObject;

  shallowlySelfPropagatePerchModuleObject =
    perchModuleObject:
    let
      hasConfig =
        perchModuleObject ? config
        || perchModuleObject ? options;

      perchModuleConfig =
        if perchModuleObject ? config
        then perchModuleObject.config
        else if perchModuleObject ? options
        then { }
        else perchModuleObject;

      perchModuleFlake =
        if perchModuleConfig ? flake
        then perchModuleConfig.flake
        else { };

      perchModulePropagated =
        if perchModuleConfig ? propagate
        then perchModuleConfig.propagate
        else { };

      exportedPerchModuleConfig =
        perchModuleConfig // {
          flake =
            perchModuleFlake
            // perchModulePropagated;
        };
    in
    if hasConfig
    then
      perchModuleObject //
      { config = exportedPerchModuleConfig; }
    else
      exportedPerchModuleConfig;

  selfPropagateImportedPerchModule =
    importedPerchModule:
    if builtins.isFunction importedPerchModule
    then
      perchModuleInputs:
      selfPropagatePerchModuleObjectImports
        (shallowlySelfPropagatePerchModuleObject
          (importedPerchModule perchModuleInputs))
    else
      selfPropagatePerchModuleObjectImports
        (shallowlySelfPropagatePerchModuleObject
          importedPerchModule);

  exportPerchModuleObjectImports = perchModuleObject:
    mapImportedPerchModuleObjectImports
      exportImportedPerchModule
      perchModuleObject;

  exportImportedPerchModule =
    importedPerchModule:
    if builtins.isFunction importedPerchModule
    then
      perchModuleInputs:
      let
        perchModuleObject =
          importedPerchModule
            (perchModuleInputs // {
              inherit self;
            });
      in
      exportPerchModuleObjectImports
        perchModuleObject
    else
      let
        perchModuleObject =
          importedPerchModule;
      in
      exportPerchModuleObjectImports
        shallowlySelfPropagatePerchModuleObject
        perchModuleObject;

  silencePerchModuleObjectImports =
    perchModuleObject:
    mapImportedPerchModuleObjectImports
      silenceImportedPerchModule
      perchModuleObject;

  shallowlySilencePerchModuleObject =
    perchModuleObject:
    let
      hasConfig =
        perchModuleObject ? config
        || perchModuleObject ? options;

      perchModuleConfig =
        if perchModuleObject ? config
        then perchModuleObject.config
        else if perchModuleObject ? options
        then { }
        else perchModuleObject;

      silencedPerchModuleConfig =
        (builtins.removeAttrs
          perchModuleConfig
          [ "flake" ]) // {
          flake =
            if perchModuleConfig ? propagate
            then perchModuleConfig.propagate
            else { };
        };
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
    mapImportedPerchModuleObjectImports
      (pruneImportedPerchModule
        prefix)
      perchModuleObject;

  shallowlyPrunePerchModuleObject =
    branch:
    perchModuleObject:
    let
      perchModuleConfig =
        if perchModuleObject ? config
        then perchModuleObject.config
        else if perchModuleObject ? options
        then { }
        else perchModuleObject;

      hasBranches =
        perchModuleConfig ? branches;

      perchModuleConfigBranches =
        if hasBranches
        then perchModuleObject.branches
        else { };

      hasPrefix =
        perchModuleConfigBranches ? ${branch};

      prunedPerchModuleConfig =
        if hasPrefix
        then perchModuleConfigBranches.${branch}
        else { };
    in
    prunedPerchModuleConfig;

  pruneImportedPerchModule =
    prefix:
    importedPerchModule:
    if builtins.isFunction importedPerchModule
    then
      perchModuleInputs:
      let
        perchModuleObject =
          importedPerchModule
            perchModuleInputs;
      in
      (prunePerchModuleObjectImports prefix)
        ((shallowlyPrunePerchModuleObject prefix)
          perchModuleObject)
    else
      let
        perchModuleObject =
          importedPerchModule;
      in
      (prunePerchModuleObjectImports prefix)
        ((shallowlyPrunePerchModuleObject prefix)
          perchModuleObject);
in
{
  options.flake.perchModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.deferredModule;
    default = { };
    description = lib.literalMD ''
      Create a `perchModules` flake output.
    '';
  };

  options.propagate = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    description = lib.literalMD ''
      Propagate flake outputs to flakes which have this flake as an input.
    '';
  };

  options.branches = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    description = lib.literalMD ''
      Register branches to be pruned by other modules.
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

      selfPropagatedModules =
        builtins.mapAttrs
          (_: module:
            selfPropagateImportedPerchModule
              (importAndMergePerchModulePath module))
          selfModules;

      allPerchModules =
        (builtins.attrValues selfPropagatedModules)
        ++ silencedPerchModules;

      perchModulesModule = {
        _module.args = {
          perchModules =
            allExportedPerchModules;
          inputPerchModules =
            silencedPerchModules;
          allPerchModules =
            allPerchModules;
        };
      };

      flakePerchModulesModule = {
        flake.perchModules =
          allExportedPerchModules;
      };
    in
    lib.evalModules {
      class = "perch";
      inherit specialArgs;
      modules =
        [ perchModulesModule flakePerchModulesModule ]
        ++ allPerchModules;
    };

  config.flake.lib.module.export = perchModule:
    exportImportedPerchModule
      (importAndMergePerchModulePath
        perchModule);

  config.flake.lib.module.silence = perchModule:
    silenceImportedPerchModule
      (importAndMergePerchModulePath
        perchModule);

  config.flake.lib.module.prune = branch: perchModule:
    (pruneImportedPerchModule branch)
      (importAndMergePerchModulePath
        perchModule);
}
