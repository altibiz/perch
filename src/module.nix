{ lib
, options
, config
, specialArgs
, nixpkgs
, ...
}@trunkArgs:

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
        functionPerchModule = perchModuleImport;
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
            perchModulePropagated
            // perchModuleFlake;
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
        perchModuleFunction = perchModuleImport;
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
          [ "flake" "seal" "branch" "integrate" ]);
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
          perchModuleFunctionArgs
          // specialArgs)
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
          [ "flake" "seal" "branch" "integrate" ]) // {
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
        perchModuleFunction = perchModuleImport;
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

      perchModuleConfigBranches =
        if perchModuleConfig ? branch
        then perchModuleConfig.branch
        else { };

      prunedPerchModuleConfig =
        if perchModuleConfigBranches ? ${branch}
        then perchModuleConfigBranches.${branch}
        else null;
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
        (mapPerchModuleFunctionArgs
          (perchModuleFunctionArgs:
          perchModuleFunctionArgs
          // specialArgs
          // {
            inherit trunkArgs;
          })
          perchModuleFunction)
    else
      let
        perchModuleObject =
          perchModuleImport;
      in
      (prunePerchModuleObjectImports branch)
        ((shallowlyPrunePerchModuleObject branch)
          perchModuleObject);

  integratePerchModuleObjectImports =
    integrate:
    perchModuleObject:
    mapPerchModuleObjectImportedImports
      (integratePerchModuleImport
        integrate)
      perchModuleObject;

  shallowlyIntegratePerchModuleObject =
    integrate:
    perchModuleObject:
    let
      perchModuleConfig =
        if perchModuleObject ? config
        then perchModuleObject.config
        else if perchModuleObject ? options
        then { }
        else perchModuleObject;

      perchModuleIntegrate =
        if perchModuleConfig ? integrate
        then perchModuleConfig.integrate
        else { };

      perchModuleIntegrateSystems =
        if perchModuleIntegrate ? systems
        then perchModuleIntegrate.systems
        else config.seal.defaults.systems;

      perchModuleIntegration =
        if perchModuleIntegrate ? ${integrate}
        then perchModuleIntegrate.${integrate}
        else null;

      perchModuleIntegrationSystems =
        if perchModuleIntegration == null
        then [ ]
        else if perchModuleIntegration ? systems
        then perchModuleIntegration.systems
        else perchModuleIntegrateSystems;

      perchModuleIntegrations =
        {
          ${integrate} = {
            systems = perchModuleIntegrationSystems;
          }
          // (builtins.listToAttrs
            (builtins.map
              (system: {
                name = system;
                value = perchModuleIntegration;
              })
              perchModuleIntegrationSystems));
        };
    in
    perchModuleIntegrations;

  integratePerchModuleImport =
    integrate:
    perchModuleImport:
    if lib.isFunction perchModuleImport
    then
      let
        perchModuleFunction = perchModuleImport;
      in
      mapPerchModuleFunctionResult
        (perchModuleObject:
        (integratePerchModuleObjectImports integrate)
          ((shallowlyIntegratePerchModuleObject integrate)
            perchModuleObject))
        (mapPerchModuleFunctionArgs
          (perchModuleFunctionArgs:
          perchModuleFunctionArgs
          // specialArgs
          // {
            inherit trunkArgs;
          })
          perchModuleFunction)
    else
      let
        perchModuleObject =
          perchModuleImport;
      in
      (integratePerchModuleObjectImports integrate)
        ((shallowlyIntegratePerchModuleObject integrate)
          perchModuleObject);
in
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

  options.systems = lib.mkOption {
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

  config.flake.lib.module.derive =
    perchModule:
    derivePerchModuleImport
      (importAndMergePerchModulePath
        perchModule);

  config.flake.lib.module.branch.prune =
    branch:
    perchModule:
    (prunePerchModuleImport branch)
      (importAndMergePerchModulePath
        perchModule);

  config.flake.lib.module.branch.artifacts =
    branch:
    perchModules:
    builtins.mapAttrs
      (_: module:
      (prunePerchModuleImport branch)
        (importAndMergePerchModulePath
          module))
      perchModules;

  config.flake.lib.module.integration.integrate =
    integrate:
    perchModule:
    (integratePerchModuleImport integrate)
      (importAndMergePerchModulePath
        perchModule);

  config.flake.lib.module.integration.artifacts =
    integrate:
    perchModules:
    let
      systemPerchModuleEval = system: module:
        let
          perchModulesModule = {
            _module.args.perchModules = perchModules;
          };

          pkgsModule = {
            _module.args.pkgs =
              import nixpkgs {
                inherit system;
              };
          };

          integrationModule =
            (integratePerchModuleImport integrate)
              (importAndMergePerchModulePath
                module);

          artifactModule = { lib, config, ... }: {
            options.${integrate} = lib.mkOption {
              type = lib.types.raw;
            };

            options.defined = lib.mkOption {
              type = lib.types.raw;
            };

            options.artifact = lib.mkOption {
              type = lib.types.raw;
            };

            config.defined =
              builtins.elem system config.${integrate}.systems;

            config.artifact =
              if builtins.elem system config.${integrate}.systems
              then config.${integrate}.${system}.${integrate}
              else null;
          };

          eval = lib.evalModules {
            inherit specialArgs;
            modules = [
              perchModulesModule
              pkgsModule
              integrationModule
              artifactModule
            ];
          };
        in
        {
          defined = eval.config.defined;
          artifact = eval.config.artifact;
        };
    in
    builtins.listToAttrs
      (builtins.filter
        (x: x != null)
        (builtins.map
          (system:
          let
            artifacts =
              builtins.listToAttrs
                (builtins.filter
                  (x: x != null)
                  (lib.mapAttrsToList
                    (name: module:
                      let
                        eval =
                          systemPerchModuleEval
                            system
                            module;
                      in
                      if eval.defined
                      then
                        {
                          inherit name;
                          value = eval.artifact;
                        }
                      else null)
                    perchModules));
          in
          if (builtins.length
            (builtins.attrNames artifacts)
          == 0)
          then null
          else
            {
              name = system;
              value = artifacts;
            })
          nixpkgs.lib.systems.flakeExposed));
}
