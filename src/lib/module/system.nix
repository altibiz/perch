{ self, lib, ... }:

{
  flake.lib.module.systems =
    specialArgs:
    perchModules:
    options:
    config:
    integration:
    modules:
    let
      systemModuleEval = system: module:
        let
          pkgsModule = { config, ... }: {
            _file = ./system.nix;

            nixpkgs.hostPlatform.system = system;
            nixpkgs.config = config.integrate.nixpkgs.config;
            nixpkgs.overlays = config.integrate.nixpkgs.overlays;
          };

          integratedModule =
            self.lib.module.integrate
              config
              integration
              module;

          isolatedModule =
            self.lib.module.isolate
              system
              integration
              integratedModule;

          definedModule = { lib, config, ... }: {
            _file = ./system.nix;

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
            # NOTE: in here instead of _module.args because
            # that causes infinite recursion
            specialArgs = specialArgs // {
              inherit perchModules;
              super = {
                inherit config options;
              };
            };
            modules = [
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
