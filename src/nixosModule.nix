{ self, lib, perchModules, ... }:

{
  options.flake.nixosModules = lib.mkOption {
    type =
      lib.types.attrsOf
        lib.types.deferredModule;
    default = { };
    description = lib.literalMD ''
      Create a `nixosModules` flake output.
    '';
  };

  options.branches.nixosModule = lib.mkOption {
    type = lib.types.raw;
    default = { };
    description = lib.literalMD ''
      `homeManagerModule` flake output branch.
    '';
  };

  options.propagate.nixosModules = lib.mkOption {
    type =
      lib.types.attrsOf
        lib.types.deferredModule;
    default = { };
    description = lib.literalMD ''
      Propagated `nixosModules` flake output.
    '';
  };

  # NOTE: this is so that perch modules can ask for pkgs but
  # this will only be evaluated in a nixosSystem context
  config._module.args = {
    pkgs = null;
  };

  config.propagate.nixosModules =
    builtins.mapAttrs
      (_: self.lib.module.prune "nixosModule")
      perchModules.current;
}
