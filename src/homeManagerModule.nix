{ self, lib, perchModules, ... }:

{
  options.branch.homeManagerModule = lib.mkOption {
    type = lib.types.raw;
    default = { };
    description = lib.literalMD ''
      `homeManagerModule` flake output branch.
    '';
  };

  options.propagate.homeManagerModules = lib.mkOption {
    type =
      lib.types.attrsOf
        lib.types.deferredModule;
    default = { };
    description = lib.literalMD ''
      Propagated `homeManagerModules` flake output.
    '';
  };

  # NOTE: this is so that perch modules can ask for pkgs but
  # this will only be evaluated in a home-manager.user context
  config._module.args = {
    pkgs = null;
  };

  config.propagate.homeManagerModules =
    let
      homeManagerModules =
        builtins.mapAttrs
          (_: self.lib.module.prune "homeManagerModule")
          perchModules.current;
    in
    if homeManagerModules ? default then homeManagerModules
    else homeManagerModules // {
      default = {
        imports = builtins.attrValues homeManagerModules;
      };
    };
}
