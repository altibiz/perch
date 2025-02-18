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
    type = lib.types.attrsOf lib.types.raw;
    default = { };
    description = lib.literalMD ''
      Create a `overlays` flake output.
    '';
  };

  options.seal.defaults.overlay = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = lib.literalMD ''
      The default `overlays` flake output.
    '';
  };

  config.propagate.overlays =
    let
      default = config.seal.defaults.overlay;
    in
    if default != null
    then
      {
        default = config.flake.overlay.${default};
      }
    else
      {
        default =
          lib.composeManyExtensions
            (builtins.attrValues
              (builtins.removeAttrs
                config.flake.overlays
                [ "default" ]));
      };
}
