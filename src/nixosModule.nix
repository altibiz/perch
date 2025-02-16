{ self, lib, selfPerchModules, ... }:

{
  options.flake.nixosModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.deferredModule;
    default = { };
    description = lib.literalMD ''
      Create a `nixosModules` flake output.
    '';
  };

  config.flake.nixosModules =
    builtins.mapAttrs
      (_: self.lib.modules.prune "system")
      selfPerchModules;
}
