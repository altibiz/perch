{ self
, lib
, nixpkgs
, flakeModules
, specialArgs
, ...
}:

let
  devShellNixpkgsModules = builtins.mapAttrs
    (module: self.lib.module.patch
      (_: args: args)
      (_: args: args)
      (_: result:
        let
          devShell =
            if result ? devShell
            then result.devShell
            else if result ? config
              && result.config ? devShell
            then result.config.devShell
            else null;

          devShellNixpkgs =
            if result ? devShellNixpkgs
            then result.devShellNixpkgs
            else if result ? config
              && result.config ? devShellNixpkgs
            then result.config.devShellNixpkgs
            else { };

          systems =
            if devShell == null then [ ]
            else if devShellNixpkgs ? system
            then [ devShellNixpkgs.system ]
            else self.lib.defaults.systems;

          configs = builtins.map
            (system: devShellNixpkgs
              // { inherit system; })
            systems;
        in
        {
          devShellNixpkgs.${module} = configs;
        }))
    flakeModules;

  devShellNixpkgsEval = lib.evalModules {
    specialArgs = specialArgs // { pkgs = null; };
    modules = (builtins.attrValues devShellNixpkgsModules) ++ [
      ({ lib, ... }: {
        options.devShellNixpkgs = lib.mkOption {
          type = lib.types.attrsOf
            (lib.types.listOf self.lib.type.nixpkgs.config);
          default = { };
        };
      })
    ];
  };

  devShellModules = builtins.mapAttrs
    (module: self.lib.module.patch
      (_: args: args)
      (_: args: args)
      (_: result:
        let
          devShell =
            if result ? devShell
            then result.devShell
            else if result ? config
              && result.config ? devShell
            then result.config.devShell
            else null;
        in
        {
          devShell.${module} = devShell;
        }))
    flakeModules;

  devShellsEval = lib.flatten
    (builtins.attrValues
      (builtins.mapAttrs
        (module: configs: builtins.map
          (config:
            let
              eval = lib.evalModules {
                specialArgs = specialArgs // {
                  pkgs = import nixpkgs config;
                };
                modules = [
                  devShellModules.${module}
                  ({ lib, ... }: {
                    options.devShell = lib.mkOption {
                      type = lib.types.attrsOf lib.types.raw;
                      default = { };
                    };
                  })
                ];
              };
            in
            {
              inherit module;
              system = config.system;
              devShell = eval.config.devShell;
            })
          configs)
        devShellNixpkgsEval.config.devShellNixpkgs));

  systems = lib.unique
    (builtins.map
      (devShell: devShell.system)
      devShellsEval);

  devShells = builtins.listToAttrs
    (builtins.map
      (system: {
        name = system;
        value = builtins.listToAttrs
          (builtins.map
            (devShell: {
              name = devShell.module;
              value = devShell.devShell;
            })
            (builtins.filter
              (devShell: devShell.system == system)
              devShellsEval));
      })
      systems);
in
{
  config.eval.allowedArgs = [ [ "pkgs" ] ];

  options.devShell = lib.mkOption {
    type = lib.types.raw;
  };
  options.devShellNixpkgs = lib.mkOption {
    type = self.lib.type.nixpkgs.config;
  };
  config.eval.privateConfig = [ [ "devShell" ] [ "devShellNixpkgs" ] ];

  options.flake.devShells = lib.mkOption {
    type = lib.types.attrsOf lib.types.raw;
    default = devShells;
  };
  config.eval.publicConfig = [ [ "flake" "devShells" ] ];
}

