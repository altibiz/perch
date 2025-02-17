{ self, lib, config, nixpkgs, ... }:

{
  options.seal.defaults.nixpkgs.overlays = lib.mkOption {
    type = lib.listOf self.lib.type.nixpkgs.overlay;
    default = [ config.flake.overlays.default ];
    description = lib.literalMD ''
      Nixpkgs config used for defaults in flake outputs.
    '';
  };

  options.seal.defaults.nixpkgs.config = lib.mkOption {
    type = self.lib.type.nixpkgs.config;
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
}
