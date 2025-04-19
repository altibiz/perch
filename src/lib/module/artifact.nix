{ nixpkgs, self, lib, ... }:

# FIXME: nixpkgs from module args

let
  systemRegex = ".*-(.*-.*)";
  hostRegex = "(.*)-.*-.*";
in
{
  flake.lib.module.artifacts =
    specialArgs:
    perchModules:
    options:
    config:
    integration:
    modules:
    let
      distill = self.lib.module.distill
        specialArgs
        perchModules
        options
        config
        (name: module: self.lib.module.patch
          ({ config, ... } @args:
            let
              pkgs =
                import nixpkgs {
                  system = builtins.head
                    (builtins.match systemRegex name);
                  config = config.distill.${name}.integrate.nixpkgs.config;
                  overlays = config.distill.${name}.integrate.nixpkgs.overlays;
                };
            in
            args // {
              inherit pkgs;
              inherit perchModules;
              super = {
                inherit config options;
              };
            })
          (result: result)
          module)
        (name: module:
          let
            system = builtins.head
              (builtins.match systemRegex name);
          in
          builtins.any
            (integrateSystem: integrateSystem == system)
            (module.integrate.systems))
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

      systems = lib.unique
        (builtins.map
          (name: builtins.head
            (builtins.match systemRegex name))
          (builtins.attrNames distill));

      forSystem = system: lib.unique
        (builtins.filter
          (name: system == (builtins.head
            (builtins.match systemRegex name)))
          (builtins.attrNames distill));
    in
    builtins.listToAttrs
      (builtins.map
        (system:
        {
          name = system;
          value = builtins.listToAttrs
            (builtins.map
              (module:
                let
                  host = builtins.head
                    (builtins.match hostRegex module);
                in
                {
                  name = host;
                  value = distill.${module}.integrate.${system};
                })
              (forSystem system));
        })
        systems);
}
