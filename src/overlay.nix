{ self, lib, config, ... }:

{
  options.flake.overlays = lib.mkOption {
    type = lib.types.attrsOf self.lib.type.overlay;
    default = { };
    description = lib.literalMD ''
      Create a `overlays` flake output.
    '';
  };

  config.flake.overlays.default =
    lib.composeManyExtensions
      (builtins.attrValues
        (builtins.removeAttrs
          config.flake.overlays
          [ "default" ]));
}
