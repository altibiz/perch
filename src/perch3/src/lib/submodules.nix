{ self
, ...
}:

{
  flake.lib.submodules.make =
    { flakeModules
    , specialArgs
    , config
    }:
    let
      filterModule =
        _: configs:
        builtins.any
          (config:
          config ? ${config}
          || config ? config
          && config.config ? ${config})
          configs;

      filteredModules = self.lib.eval.filter
        specialArgs
        filterModule
        flakeModules;

      configModules = builtins.mapAttrs
        (_: self.lib.module.patch
          (_: args: args)
          (_: args: args)
          (_: result:
            if result ? ${config}
            then result.${config}
            else if result ? config
              && result.config ? ${config}
            then result.config.${config}
            else { }))
        filteredModules;
    in
    configModules;
}

