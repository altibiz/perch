{ self, lib, ... }:

let
  importPerchModule =
    perchModule:
    if (builtins.isPath perchModule)
      || (builtins.isString perchModule)
    then
      import perchModule
    else perchModule;

  mapPerchModuleFunctionResult =
    mapping:
    perchModuleFunction:
    let
      args =
        lib.getFunctionArgs
          perchModuleFunction;

      mapped =
        perchModuleArgs:
        mapping
          (perchModuleFunction
            perchModuleArgs);
    in
    lib.setFunctionArgs
      mapped
      args;

  mapPerchModuleFunctionArgs =
    mapping:
    perchModuleFunction:
    let
      args =
        lib.getFunctionArgs
          perchModuleFunction;

      mapped =
        args:
        perchModuleFunction
          (mapping
            args);
    in
    lib.setFunctionArgs
      mapped
      args;

  importAndMergePerchModulePath =
    perchModule:
    let
      perchModulePathPart =
        if (builtins.isPath perchModule)
          || (builtins.isString perchModule)
        then {
          _file = perchModule;
        }
        else { };

      perchModuleImport =
        importPerchModule
          perchModule;
    in
    if builtins.isFunction perchModuleImport
    then
      let
        functionPerchModule = importPerchModule;
      in
      mapPerchModuleFunctionResult
        (perchModuleObject:
        perchModuleObject
        // perchModulePathPart)
        functionPerchModule
    else
      let
        perchModuleObject =
          perchModuleImport;
      in
      perchModuleObject
      // perchModulePathPart;

  mapPerchModuleImportObjectImports =
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
    mapPerchModuleImportObjectImports
      selfPropagatePerchModuleImport
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

  selfPropagatePerchModuleImport =
    perchModuleImport:
    if builtins.isFunction perchModuleImport
    then
      let
        perchModuleFunction = importPerchModule;
      in
      mapPerchModuleFunctionResult
        (perchModuleObject:
        selfPropagatePerchModuleObjectImports
          (shallowlySelfPropagatePerchModuleObject
            perchModuleObject))
        perchModuleFunction
    else
      selfPropagatePerchModuleObjectImports
        (shallowlySelfPropagatePerchModuleObject
          perchModuleImport);

  exportPerchModuleObjectImports =
    perchModuleObject:
    mapPerchModuleImportObjectImports
      exportPerchModuleImport
      perchModuleObject;

  shallowlyExportPerchModuleObject =
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

      exportedPerchModuleConfig =
        (builtins.removeAttrs
          perchModuleConfig
          [ "flake" ]);
    in
    if hasConfig
    then
      perchModuleObject //
      { config = exportedPerchModuleConfig; }
    else
      exportedPerchModuleConfig;

  exportPerchModuleImport =
    perchModuleImport:
    if builtins.isFunction perchModuleImport
    then
      let
        perchModuleFunction = perchModuleImport;
      in
      mapPerchModuleFunctionResult
        (perchModuleObject:
        exportPerchModuleObjectImports
          (shallowlyExportPerchModuleObject
            perchModuleObject))
        (mapPerchModuleFunctionArgs
          (perchModuleArgs: perchModuleArgs // {
            inherit self;
          })
          perchModuleFunction)
    else
      let
        perchModuleObject =
          perchModuleImport;
      in
      exportPerchModuleObjectImports
        (shallowlyExportPerchModuleObject
          perchModuleObject);

  derivePerchModuleObjectImports =
    perchModuleObject:
    mapPerchModuleImportObjectImports
      derivePerchModuleImport
      perchModuleObject;

  shallowlyDerivePerchModuleObject =
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

      derivedPerchModuleConfig =
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
      { config = derivedPerchModuleConfig; }
    else
      derivedPerchModuleConfig;

  derivePerchModuleImport =
    perchModuleImport:
    if builtins.isFunction perchModuleImport
    then
      let
        perchModuleFunction = importPerchModule;
      in
      mapPerchModuleFunctionResult
        (perchModuleObject:
        derivePerchModuleObjectImports
          (shallowlyDerivePerchModuleObject
            perchModuleObject))
        perchModuleFunction
    else
      derivePerchModuleObjectImports
        (shallowlyDerivePerchModuleObject
          perchModuleImport);

  prunePerchModuleObjectImports =
    prefix:
    perchModuleObject:
    mapPerchModuleImportObjectImports
      (prunePerchModuleImport
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

  prunePerchModuleImport =
    prefix:
    perchModuleImport:
    if builtins.isFunction perchModuleImport
    then
      let
        perchModuleFunction = perchModuleImport;
      in
      mapPerchModuleFunctionResult
        (perchModuleObject:
        (prunePerchModuleObjectImports prefix)
          ((shallowlyPrunePerchModuleObject prefix)
            perchModuleObject))
        perchModuleFunction
    else
      let
        perchModuleObject =
          perchModuleImport;
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
            exportPerchModuleImport
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

      derivedPerchModules =
        builtins.map
          (perchModule:
            derivePerchModuleImport
              (importAndMergePerchModulePath
                perchModule))
          inputModules;

      selfPropagatedModules =
        builtins.mapAttrs
          (_: module:
            selfPropagatePerchModuleImport
              (importAndMergePerchModulePath
                module))
          selfModules;

      allPerchModules =
        (builtins.attrValues selfPropagatedModules)
        ++ derivedPerchModules;

      perchModulesModule = {
        _module.args = {
          perchModules =
            selfPropagatedModules;
          derivedPerchModules =
            derivedPerchModules;
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
      modules = [
        perchModulesModule
        flakePerchModulesModule
      ] ++ allPerchModules;
    };

  config.flake.lib.module.derive = perchModule:
    derivePerchModuleImport
      (importAndMergePerchModulePath
        perchModule);

  config.flake.lib.module.prune = branch: perchModule:
    (prunePerchModuleImport branch)
      (importAndMergePerchModulePath
        perchModule);
}
