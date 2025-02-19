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
    # type = lib.types.attrsOf lib.types.raw;
    type = lib.types.raw;
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
    if !(config.flake ? overlay)
    then { }
    else
      let
        default = config.seal.defaults.overlay;

        defaultOverlay =
          if default != null
          then config.flake.overlay.${default}
          else if config.flake.overlay ? default
          then config.flake.overlay.default
          else
            lib.composeManyExtensions
              (builtins.attrValues
                (builtins.removeAttrs
                  config.flake.overlays
                  [ "default" ]));
      in
      config.flake.overlay //
      { default = defaultOverlay; };
}
