{ self, lib, nixpkgs, ... }:

{
  flake.lib.module.artifacts =
    specialArgs:
    perchModules:
    options:
    config:
    integration:
    modules:
    let
      systemModuleEval = system: module:
        let
          integrationModule =
            self.lib.module.integrate
              integration
              module;

          pkgsModule = { config, ... }: {
            _module.args.pkgs =
              import nixpkgs {
                inherit system;
                config = config.integrate.nixpkgs.config;
                overlays = config.integrate.nixpkgs.overlays;
              };
          };

          artifactModule = { lib, config, ... }: {
            options.integrate = lib.mkOption {
              type = lib.types.raw;
            };

            options.defined = lib.mkOption {
              type = lib.types.raw;
            };

            options.artifact = lib.mkOption {
              type = lib.types.raw;
            };

            config.defined =
              builtins.elem
                system
                (lib.attrByPath
                  [ "integrate" "systems" ]
                  [ ]
                  config);

            config.artifact =
              if config.defined
              then config.integrate.${system}.${integration}
              else null;
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
            modules = [
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

      systemArtifacts = system:
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
              modules));
    in
    builtins.listToAttrs
      (builtins.filter
        (x: x != null)
        (builtins.map
          (system:
          let
            artifacts = systemArtifacts system;
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
          self.lib.defaults.systems));
}
