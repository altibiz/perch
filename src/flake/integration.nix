{ lib, config, ... }:

{
  options.integrate.systems = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = config.seal.defaults.systems;
    description = lib.literalMD ''
      List of systems in which to integrate.
    '';
  };

  options.integrate.nixpkgs.overlays = lib.mkOption {
    # FIXME: type error
    # type = lib.types.listOf self.lib.type.overlay;
    type = lib.types.raw;
    default = config.seal.defaults.nixpkgs.overlays;
    description = lib.literalMD ''
      Nixpkgs overlays in which to integrate.
    '';
  };

  options.integrate.nixpkgs.config = lib.mkOption {
    # FIXME: type error
    # type = self.lib.type.nixpkgs.config;
    type = lib.types.raw;
    default = config.seal.defaults.nixpkgs.config;
    description = lib.literalMD ''
      Nixpkgs config in which to integrate.
    '';
  };
}
