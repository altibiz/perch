{ self, lib, nixpkgs, specialArgs, perchModules, ... }:

{
  flake.lib.module.systems =
    integration:
    modules:
    let
      systemModuleEval = system: module:
        let
          perchModulesModule = {
            _module.args.perchModules = perchModules;
          };

          pkgsModule = { config, ... }: {
            nixpkgs.hostPlatform.system = system;
            nixpkgs.config = config.${integration}.nixpkgs.config;
            nixpkgs.overlays = config.${integration}.nixpkgs.overlays;
          };

          integratedModule =
            self.lib.module.integrate
              integration
              module;

          isolatedModule =
            self.lib.module.isolate
              system
              integration
              integratedModule;

          definedModule = { lib, config, ... }: {
            options.integrate = lib.mkOption {
              type = lib.types.raw;
            };

            options.defined = lib.mkOption {
              type = lib.types.raw;
            };

            config.defined =
              builtins.elem
                system
                (lib.attrByPath
                  [ "integrate" "systems" ]
                  [ ]
                  config);
          };

          eval = lib.nixosSystem {
            inherit specialArgs;
            modules = [
              perchModulesModule
              pkgsModule
              integratedModule
              isolatedModule
              definedModule
            ];
          };
        in
        {
          defined = eval.config.defined;
          system = eval;
        };
    in
    builtins.listToAttrs
      (builtins.filter
        (x: x != null)
        (builtins.map
          ({ system, module }:
          let
            eval = systemModuleEval system module;
          in
          if eval.defined then {
            name = "${module.name}-${system}";
            value = module.module;
          } else null)
          (lib.cartesianProduct {
            system = nixpkgs.lib.systems.flakeExposed;
            module =
              lib.mapAttrsToList
                (name: module: {
                  inherit name module;
                })
                modules;
          })));
}
