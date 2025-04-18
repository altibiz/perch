{ self, lib, ... }:

let
  systemRegex = ".*-(.*-.*)";
  # hostRegex = "(.*)-.*-.*";
in
{
  flake.lib.module.systems =
    specialArgs:
    perchModules:
    options:
    config:
    integration:
    modules:
    let
      modulesSystems =
        (builtins.listToAttrs
          (builtins.map
            ({ system, module }:
              let
                integratedModule =
                  self.lib.module.integrate
                    config
                    integration
                    modules.${module};
              in
              {
                name = "${module}-${system}";
                value = integratedModule;
              })
            (lib.cartesianProduct {
              system = self.lib.defaults.systems;
              module = builtins.attrNames modules;
            })));

      distill = self.lib.module.distill
        specialArgs
        perchModules
        options
        config
        (_: integratedModule: integratedModule)
        (name: module:
          let
            system = builtins.head
              (builtins.match systemRegex name);
          in
          builtins.any
            (integrateSystem: integrateSystem == system)
            module.integrate.systems)
        modulesSystems;
    in
    builtins.mapAttrs
      (name: _:
      let
        system = builtins.head
          (builtins.match systemRegex name);

        integratedModule =
          modulesSystems.${name};

        isolatedModule =
          self.lib.module.isolate
            system
            integration
            integratedModule;

        integrateModule = {
          options.integrate = lib.mkOption {
            type = lib.types.raw;
          };
        };

        pkgsModule = { config, ... }: {
          _file = ./system.nix;

          nixpkgs.hostPlatform.system = system;
          nixpkgs.config = config.integrate.nixpkgs.config;
          nixpkgs.overlays = config.integrate.nixpkgs.overlays;
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
            integrateModule
            integratedModule
            isolatedModule
          ];
        };
      in
      eval)
      distill;
}
