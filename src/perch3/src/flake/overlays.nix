{ self, lib, ... }:

{
  options.flake.overlays = lib.mkOption {
    type = lib.types.attrsOf self.lib.type.overlay;
    default = { };
    description = lib.literalMD ''
      `lib` flake output.
    '';
  };
  eval.publicConfig = [ [ "flake" "overlays" ] ];
}
