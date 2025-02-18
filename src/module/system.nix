{ self
, lib
, specialArgs
, perchModules
, config
, options
, ...
}:

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

          superModule = {
            _module.args.super = {
              inherit config options;
            };
          };

          pkgsModule = { config, ... }: {
            nixpkgs.hostPlatform.system = system;
            nixpkgs.config = config.integrate.nixpkgs.config;
            nixpkgs.overlays = config.integrate.nixpkgs.overlays;
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
              superModule
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
            eval = systemModuleEval system module.module;
          in
          if eval.defined then {
            name = "${module.name}-${system}";
            value = eval.system;
          } else null)
          (lib.cartesianProduct {
            system = self.lib.defaults.systems;
            module =
              lib.mapAttrsToList
                (name: module: {
                  inherit name module;
                })
                modules;
          })));
}
