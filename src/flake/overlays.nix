{ self
, lib
, config
, ...
}:

{
  options.propagate.overlays = lib.mkOption {
    type = lib.types.attrsOf self.lib.type.overlay;
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
    if !(config.flake ? overlays)
    then { }
    else
      let
        default = config.seal.defaults.overlay;

        defaultOverlay =
          if default != null
          then config.flake.overlays.${default}
          else if config.flake.overlays ? default
          then config.flake.overlays.default
          else
            lib.composeManyExtensions
              (builtins.attrValues
                (builtins.removeAttrs
                  config.flake.overlays
                  [ "default" ]));
      in
      config.flake.overlays //
      { default = defaultOverlay; };
}
