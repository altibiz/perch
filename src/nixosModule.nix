{ self, lib, perchModules, ... }:

{
  options.flake.nixosModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.deferredModule;
    default = { };
    description = lib.literalMD ''
      Create a `nixosModules` flake output.
    '';
  };

  config.propagate.nixosModules =
    self.lib.module.prune
      "system"
      perchModules.default;
}
