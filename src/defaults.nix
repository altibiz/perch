{ lib, nixpkgs, ... }:

{
  options.seal.defaults.nixpkgs.overlays = lib.mkOption {
    # FIXME: type error
    # type = lib.types.listOf self.lib.type.overlay;
    type = lib.types.raw;
    default = [
      # FIXME: default not found
      # config.flake.overlays.default 
    ];
    description = lib.literalMD ''
      Nixpkgs config used for defaults in flake outputs.
    '';
  };

  options.seal.defaults.nixpkgs.config = lib.mkOption {
    # FIXME: type error
    # type = self.lib.type.nixpkgs.config;
    type = lib.types.raw;
    default = { };
    description = lib.literalMD ''
      Nixpkgs config used for defaults in flake outputs.
    '';
  };

  options.seal.defaults.systems = lib.mkOption {
    type =
      lib.types.listOf
        lib.types.str;
    default = nixpkgs.lib.systems.flakeExposed;
    description = lib.literalMD ''
      Default list of systems in which to integrate.
    '';
  };

  options.seal.defaults.packagesAsApps = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = lib.literalMD ''
      Convert all packages to apps.
    '';
  };
}
