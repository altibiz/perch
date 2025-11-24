{ self, lib, ... }:

{
  flake.lib3.eval.prune =
    specialArgs:
    filterModule:
    modules:
    let
      mappedModules =
        (builtins.map
          (module: self.lib3.module.patch
            (args: lib.mapAttrs
              (name: value: if specialArgs ? ${name} then true else value)
              args)
            (args: specialArgs // args)
            (result:
              let
                config =
                  if result ? config
                  then { distill.${module} = [ result.config ]; }
                  else if result ? options
                  then { }
                  else { distill.${module} = [ result ]; };
              in
              {
                inherit config;
              })
            modules.${module})
          (builtins.attrNames modules));

      definedModule = { lib, config, ... }: {
        _file = ./distill.nix;
        key = ./distill.nix;

        options.distill = lib.mkOption {
          type = lib.types.attrsOf (lib.types.listOf lib.types.raw);
        };

        options.defined = lib.mkOption {
          type = lib.types.attrsOf lib.types.bool;
        };

        config.defined = builtins.listToAttrs
          (builtins.map
            (module: {
              name = module;
              value = filterModule config.distill.${module};
            })
            (builtins.attrNames modules));
      };

      eval = lib.evalModules {
        inherit specialArgs;
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
