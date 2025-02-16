{ self, lib, config, perchModules, specialArgs, ... }:

{
  options.branches.nixosConfiguration = lib.mkOption {
    type = lib.types.raw;
    default = { };
    description = lib.literalMD ''
      `nixosConfigurations` flake output branch.
    '';
  };

  options.propagate.nixosConfigurations = lib.mkOption {
    type = lib.types.attrsOf lib.types.raw;
    default = { };
    description = lib.literalMD ''
      Propagated `nixosConfigurations` flake output.
    '';
  };

  # NOTE: this is so that perch modules can ask for pkgs but
  # this will only be evaluated in a nixosSystem context
  config._module.args = {
    pkgs = null;
  };

  config.propagate.nixosConfigurations =
    builtins.mapAttrs
      (_: module:
        let
          configurationModule =
            self.lib.module.prune
              "nixosConfiguration"
              module;

          perchModulesModule = {
            _module.args.perchModules = perchModules;
          };
        in
        lib.nixosSystem {
          inherit specialArgs;
          # NOTE: let system be set mudularly
          system = null;
          modules = [
            perchModulesModule
            configurationModule
            config.flake.nixosModules.default
          ];
        })
      perchModules.current;
}
