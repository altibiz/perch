{ self, lib, ... }:

{
  options.flake.overlays = lib.mkOption {
    type = lib.types.listOf self.lib.type.overlay;
    default = [ ];
    description = lib.literalMD ''
      Create a `overlays` flake output.
    '';
  };
}
