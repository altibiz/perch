{ self, lib, perchModules, ... }:

{
  options.flake.homaManagerModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.deferredModule;
    default = { };
    description = lib.literalMD ''
      Create a `homeManagerModules` flake output.
    '';
  };

  # NOTE: this is so that perch modules can ask for pkgs but
  # this will only be evaluated in a home-manager.user context
  config._module.args = {
    pkgs = null;
  };

  config.propagate.homeManagerModules =
    builtins.mapAttrs
      (_: self.lib.module.prune "home")
      perchModules;
}
