{ self, lib, nixpkgs, specialArgs, ... }:

{
  flake.lib.module.leaves =
    branch:
    modules:
    builtins.mapAttrs
      (_: module:
      self.lib.module.prune branch module)
      modules;

  flake.lib.module.artifacts =
    integration:
    module:
    let
      systemModuleEval = system: module:
        let
          perchModulesModule = {
            _module.args.perchModules = module;
          };

          pkgsModule = { config, ... }: {
            _module.args.pkgs =
              import nixpkgs {
                inherit system;
                config = config.${integration}.nixpkgs.config;
                overlays = config.${integration}.nixpkgs.overlays;
              };
          };

          integrationModule =
            self.lib.module.integrate
              integration
              module;

          artifactModule = { lib, config, ... }: {
            options.${integration} = lib.mkOption {
              type = lib.types.raw;
            };

            options.defined = lib.mkOption {
              type = lib.types.raw;
            };

            options.artifact = lib.mkOption {
              type = lib.types.raw;
            };

            config.defined =
              builtins.elem system config.${integration}.systems;

            config.artifact =
              if builtins.elem system config.${integration}.systems
              then config.${integration}.${system}.${integration}
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
                          systemModuleEval
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
                    module));
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
