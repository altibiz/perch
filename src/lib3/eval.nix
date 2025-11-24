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
}
