{ lib, options, ... }:

{
  options.flake = {
    perchModules = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = { };
      description = lib.literalMD ''
        `perchModules` flake output.
      '';
    };
  }
  // (builtins.mapAttrs
    (name: option: option // {
      description = lib.literalMD ''
        Propagated `${name}` flake output.
      '';
    })
    options.propagate);
}
