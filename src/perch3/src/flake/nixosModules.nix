{ self
, lib
, flakeModules
, specialArgs
, ...
}:

let
  filterModule =
    _: configs:
    builtins.any
      (config:
      config ? nixosModule
      || config ? config
      && config.config ? nixosModule)
      configs;

  filteredModules = self.lib.eval.filter
    specialArgs
    filterModule
    flakeModules;

  nixosModules = builtins.mapAttrs
    (_: self.lib.module.patch
      (_: args: args)
      (_: args: args)
      (_: result:
        if result ? nixosModule
        then result.nixosModule
        else if result ? config
          && result.config ? nixosModule
        then result.config.nixosModule
        else { }))
    filteredModules;
in
{
  options.nixosModule = lib.mkOption {
    type = lib.types.attrsOf lib.types.raw;
  };
  config.eval.privateConfig = [ [ "nixosModule" ] ];

  options.flake.nixosModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.raw;
    default =
      nixosModules // {
        default = {
          imports = builtins.attrValues nixosModules;
        };
      };
  };
  config.eval.publicConfig = [ [ "flake" "nixosModules" ] ];
}

