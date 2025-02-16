{ self, lib, ... }:

let
  mapPerchModuleFunctionResult =
    perchModuleFunctionResultMapping:
    perchModuleFunction:
    let
      perchModuleFunctionArgs =
        lib.functionArgs
          perchModuleFunction;

      mappedPerchModuleFunction =
        perchModuleFunctionArgs:
        perchModuleFunctionResultMapping
          (perchModuleFunction
            perchModuleFunctionArgs);
    in
    lib.setFunctionArgs
      mappedPerchModuleFunction
      perchModuleFunctionArgs;

  mapPerchModuleFunctionArgs =
    perchModuleFunctionArgsMapping:
    perchModuleFunction:
    let
      perchModuleFunctionArgs =
        lib.functionArgs
          perchModuleFunction;

      mappedPerchModuleFunction =
        perchModuleFunctionArgs:
        perchModuleFunction
          (perchModuleFunctionArgsMapping
            perchModuleFunctionArgs);
    in
    lib.setFunctionArgs
      mappedPerchModuleFunction
      perchModuleFunctionArgs;

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
        then
          let
            perchModulePath = perchModule;
          in
          {
            _file = perchModulePath;
            key = perchModulePath;
          }
        else
          { };

      perchModuleImport =
        importPerchModule
          perchModule;
    in
    if lib.isFunction perchModuleImport
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

  mapPerchModuleObjectImportedImports =
    perchModuleImportMapping:
    perchModuleObject:
    if perchModuleObject ? imports
    then
      perchModuleObject // {
        imports =
          builtins.map
            (perchModule:
              perchModuleImportMapping
                (importAndMergePerchModulePath
                  perchModule))
            perchModuleObject.imports;
      }
    else
      perchModuleObject;

  selfPropagatePerchModuleObjectImports =
    perchModuleObject:
    mapPerchModuleObjectImportedImports
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
    if lib.isFunction perchModuleImport
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
    mapPerchModuleObjectImportedImports
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
    if lib.isFunction perchModuleImport
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
          (perchModuleFunctionArgs:
          perchModuleFunctionArgs // {
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
    mapPerchModuleObjectImportedImports
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
    if lib.isFunction perchModuleImport
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
    branch:
    perchModuleObject:
    mapPerchModuleObjectImportedImports
      (prunePerchModuleImport
        branch)
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

      hasBranch =
        perchModuleConfigBranches ? ${branch};

      prunedPerchModuleConfig =
        if hasBranch
        then perchModuleConfigBranches.${branch}
        else { };
    in
    prunedPerchModuleConfig;

  prunePerchModuleImport =
    branch:
    perchModuleImport:
    if lib.isFunction perchModuleImport
    then
      let
        perchModuleFunction = perchModuleImport;
      in
      mapPerchModuleFunctionResult
        (perchModuleObject:
        (prunePerchModuleObjectImports branch)
          ((shallowlyPrunePerchModuleObject branch)
            perchModuleObject))
        perchModuleFunction
    else
      let
        perchModuleObject =
          perchModuleImport;
      in
      (prunePerchModuleObjectImports branch)
        ((shallowlyPrunePerchModuleObject branch)
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
        (builtins.attrValues
          selfPropagatedModules)
        ++ derivedPerchModules;

      perchModulesModule = {
        _file = ./module.nix;
        key = ./module.nix;
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
