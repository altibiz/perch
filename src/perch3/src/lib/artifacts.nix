{ self
, lib
, ...
}:

{
  flake.lib.artifacts.make =
    { specialArgs
    , flakeModules
    , nixpkgs
    , nixpkgsConfig
    , config
    }:
    let
      nixpkgsAttrModules = builtins.mapAttrs
        (module: self.lib.module.patch
          (_: args: args)
          (_: args: args)
          (_: result:
            let
              value =
                if result ? ${config}
                then result.${config}
                else if result ? config
                  && result.config ? ${config}
                then result.config.${config}
                else null;

              nixpkgs =
                if result ? ${nixpkgsConfig}
                then result.${nixpkgsConfig}
                else if result ? config
                  && result.config ? ${nixpkgsConfig}
                then result.config.${nixpkgsConfig}
                else { };

              systems =
                if value == null then [ ]
                else if nixpkgs ? system
                then [ nixpkgs.system ]
                else self.lib.defaults.systems;

              configs = builtins.map
                (system: nixpkgs
                  // { inherit system; })
                systems;
            in
            {
              nixpkgs.${module} = configs;
            }))
        flakeModules;

      nixpkgsAttrEval = lib.evalModules {
        specialArgs = specialArgs // { pkgs = null; };
        modules = (builtins.attrValues nixpkgsAttrModules) ++ [
          ({ lib, ... }: {
            options.nixpkgs = lib.mkOption {
              type = lib.types.attrsOf
                (lib.types.listOf self.lib.type.nixpkgs.config);
              default = { };
            };
          })
        ];
      };

      valueModules = builtins.mapAttrs
        (module: self.lib.module.patch
          (_: args: args)
          (_: args: args)
          (_: result:
            let
              value =
                if result ? ${config}
                then result.${config}
                else if result ? config
                  && result.config ? ${config}
                then result.config.${config}
                else null;
            in
            {
              inherit value;
            }))
        flakeModules;

      valuesEval = lib.flatten
        (builtins.attrValues
          (builtins.mapAttrs
            (module: configs: builtins.map
              (conf:
                let
                  eval = lib.evalModules {
                    specialArgs = specialArgs // {
                      pkgs = import nixpkgs conf;
                    };
                    modules = [
                      valueModules.${module}
                      ({ lib, ... }: {
                        options.value = lib.mkOption {
                          type = lib.types.raw;
                          default = { };
                        };
                      })
                    ];
                  };
                in
                {
                  inherit module;
                  system = conf.system;
                  value = eval.config.value;
                })
              configs)
            nixpkgsAttrEval.config.nixpkgs));

      systems = lib.unique
        (builtins.map
          (attr: attr.system)
          valuesEval);

      values = builtins.listToAttrs
        (builtins.map
          (system: {
            name = system;
            value = builtins.listToAttrs
              (builtins.map
                (value: {
                  name = value.module;
                  value = value.value;
                })
                (builtins.filter
                  (value: value.system == system)
                  valuesEval));
          })
          systems);
    in
    values;
}
