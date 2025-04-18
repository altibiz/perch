{ self, lib, ... }:

{
  flake.lib.module.distill =
    specialArgs:
    perchModules:
    options:
    config:
    map':
    filter':
    modules:
    let
      mappedModules =
        (builtins.map
          (module: self.lib.module.patch
            (args: args)
            (result:
              let
                config =
                  if result ? config
                  then { distill.${module} = result.config; }
                  else if result ? options
                  then { }
                  else { distill.${module} = result; };
              in
              {
                inherit config;
              })
            (map' module modules.${module}))
          (builtins.attrNames modules));

      definedModule = { lib, config, ... }: {
        _file = ./distill.nix;

        options.distill = lib.mkOption {
          type = lib.types.attrsOf lib.types.raw;
        };

        options.defined = lib.mkOption {
          type = lib.types.attrsOf lib.types.bool;
        };

        config.defined = builtins.listToAttrs
          (builtins.map
            (module: {
              name = module;
              value = filter' module config.distill.${module};
            })
            (builtins.attrNames modules));
      };

      eval = lib.evalModules {
        # NOTE: in here instead of _module.args because
        # that causes infinite recursion
        specialArgs = specialArgs // {
          inherit perchModules;
          super = {
            inherit config options;
          };
        };
        modules =
          [ definedModule ]
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
              if eval.config.defined.${module}
              then eval.config.distill.${module}
              else null;
          })
          (builtins.attrNames modules)));
}
