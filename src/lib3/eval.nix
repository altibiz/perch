{ self, lib, ... }:

{
  flake.lib3.eval.filter =
    specialArgs:
    filterModule:
    modules:
    let
      mappedModules = builtins.map
        (module: self.lib3.module.patch
          (_: args: args)
          (function: args:
            let
              requestedArgs = lib.functionArgs function;
            in
            builtins.mapAttrs
              (name: _:
                if args ? ${name}
                then args.${name}
                else null)
              requestedArgs)
          (_: result:
            let
              config =
                if result ? config
                then [ result.config ]
                else if result ? options
                then [ ]
                else [ result ];
              options =
                if result ? options
                then [ result.options ]
                else [ ];
            in
            {
              original.config.${module} = config;
              original.options.${module} = options;
            })
          modules.${module})
        (builtins.attrNames modules);

      filteringModule = { lib, config, ... }: {
        _file = ./eval.nix;
        key = ./eval.nix;

        options.original.options = lib.mkOption {
          type = lib.types.attrsOf (lib.types.listOf lib.types.raw);
          default = { };
        };

        options.original.config = lib.mkOption {
          type = lib.types.attrsOf (lib.types.listOf lib.types.raw);
          default = { };
        };

        options.filtered = lib.mkOption {
          type = lib.types.attrsOf lib.types.bool;
          default = { };
        };

        config.filtered = builtins.listToAttrs
          (builtins.map
            (module: {
              name = module;
              value = filterModule
                config.original.options.${module}
                config.original.config.${module};
            })
            (builtins.attrNames modules));
      };

      eval = lib.evalModules {
        inherit specialArgs;
        modules =
          [ filteringModule ]
          ++ mappedModules;
      };
    in
    builtins.listToAttrs
      (builtins.filter
        ({ value, ... }: value != null)
        (builtins.map
          (module: {
            name = module;
            value =
              if eval.config.filtered.${module}
              then modules.${module}
              else null;
          })
          (builtins.attrNames modules)));

  flake.lib3.eval.flake =
    specialArgs:
    inputModules:
    selfModules:
    let
      anyStageEvalModule = { lib, ... }: {
        _file = ./eval.nix;
        key = "eval";

        options = {
          eval.privateConfig = lib.mkOption {
            type = lib.types.listOf
              (lib.types.listOf
                lib.types.str);
            default = [ ];
          };

          eval.publicConfig = lib.mkOption {
            type = lib.types.listOf
              (lib.types.listOf
                lib.types.str);
            default = [ ];
          };

          eval.allowedArgs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };

          flake = {
            modules = lib.mkOption {
              type = lib.types.attrsOf lib.types.deferredModule;
              default = { };
              description = lib.literalMD ''
                `modules` flake output.
              '';
            };
          };
        };

        config = {
          eval.privateConfig = [
            [ "flake" "modules" ]
          ];

          eval.publicConfig = [
            [ "eval" "privateConfig" ]
            [ "eval" "publicConfig" ]
            [ "eval" "allowedArgs" ]
          ];
        };
      };

      inputModuleList = lib.flatten
        (builtins.map
          builtins.attrValues
          (builtins.attrValues
            inputModules));

      selfModuleList = builtins.attrValues selfModules;

      stageOneModules = builtins.map
        (module: self.lib3.module.patch
          (_: args: args)
          (function: args:
            let
              requestedArgs = lib.functionArgs function;
            in
            builtins.mapAttrs
              (name: _:
                if args ? ${name}
                then args.${name}
                else null)
              requestedArgs)
          (_: result: result)
          module)
        (inputModuleList ++ selfModuleList);

      stageOneEvalModule = { lib, ... }: {
        _file = ./eval.nix;
        key = "evalStageOne";
      };

      stageOneEval = lib.evalModules {
        class = "flake";
        specialArgs = specialArgs;
        modules =
          [ anyStageEvalModule stageOneEvalModule ]
          ++ stageOneModules;
      };

      privateAttrs = builtins.concatLists
        (builtins.map
          (path: [ ([ "config" ] ++ path) path ])
          stageOneEval.config.eval.privateConfig);
      publicAttrs = (builtins.concatLists
        (builtins.map
          (path: [ ([ "config" ] ++ path) path ])
          stageOneEval.config.eval.publicConfig))
      ++ [ [ "_file" ] [ "key" ] ];
      allowedArgs = stageOneEval.config.eval.allowedArgs;

      stageTwoModules = builtins.map
        (module: self.lib3.module.patch
          (_: args: builtins.mapAttrs
            (name: optional: optional
              || builtins.elem name allowedArgs)
            args)
          (function: args:
            let
              requestedArgs = lib.functionArgs function;
            in
            builtins.mapAttrs
              (name: _:
                if args ? ${name}
                then args.${name}
                else null)
              (lib.filterAttrs
                (name: value:
                  args ? ${name}
                  || builtins.elem name allowedArgs)
                requestedArgs))
          (_: result: result))
        ((builtins.map
          (module: self.lib3.module.patch
            (_: args: args)
            (_: args: args)
            (_: result:
              self.lib3.attrset.removeAttrsByPath
                privateAttrs
                result)
            module)
          inputModuleList) ++ selfModuleList);

      flakeModules = (builtins.mapAttrs
        (_: module: self.lib3.module.patch
          (_: args: args)
          (_: args: args)
          (_: result:
            self.lib3.attrset.keepAttrsByPath
              publicAttrs
              result)
          module)
        selfModules);

      stageTwoEvalModule = { options, ... }: {
        _file = ./eval.nix;
        key = "evalStageTwo";

        _module.args = {
          flakeModules = selfModuleList;
        };

        config = {
          flake.modules = flakeModules;
        };
      };

      stageTwoEval = lib.evalModules {
        class = "flake";
        specialArgs = specialArgs;
        modules =
          [ anyStageEvalModule stageTwoEvalModule ]
          ++ stageTwoModules;
      };
    in
    stageTwoEval;
}
