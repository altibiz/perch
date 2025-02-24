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

  options.seal.overlays = lib.mkOption {
    type = lib.types.attrsOf self.lib.type.overlay;
    default = { };
    description = lib.literalMD ''
      Create a `overlays` flake output with default.
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
          then config.seal.overlays.${default}
          else if config.seal.overlays ? default
          then config.seal.overlays.default
          else
            lib.composeManyExtensions
              (builtins.attrValues
                (builtins.removeAttrs
                  config.seal.overlays
                  [ "default" ]));
      in
      config.seal.overlays //
      { default = defaultOverlay; };
}
