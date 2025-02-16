{ self, lib, config, perchModules, specialArgs, ... }:

{
  options.flake.nixosConfigurations = lib.mkOption {
    type = lib.types.attrsOf lib.types.deferredModule;
    default = { };
    description = lib.literalMD ''
      Create a `nixosConfigurations` flake output.
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
              "configuration"
              module;

          flakeNixosModules =
            builtins.attrValues
              config.flake.nixosModules;

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
          ] ++ flakeNixosModules;
        })
      perchModules.current;
}
