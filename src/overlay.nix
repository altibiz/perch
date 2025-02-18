{
  # self, 
  lib
, config
, ...
}:

{
  options.propagate.overlays = lib.mkOption {
    # FIXME: causes infinite recursion
    # type = lib.types.attrsOf self.lib.type.overlay;
    type = lib.types.raw;
    default = { };
    description = lib.literalMD ''
      Create a `overlays` flake output.
    '';
  };

  options.seal.overlays = lib.mkOption {
    # FIXME: causes type error
    # type = lib.types.attrsOf self.lib.type.overlay;
    type = lib.types.raw;
    default = { };
    description = lib.literalMD ''
      Create a `overlays` flake output with composed default.
    '';
  };

  config.propagate.overlays = {
    default =
      lib.composeManyExtensions
        (builtins.attrValues
          (builtins.removeAttrs
            config.seal.overlays
            [ "default" ]));
  };
}
