{ self, lib, config, ... }:

{
  options.seal.defaults.nixpkgs.overlays = lib.mkOption {
    type = lib.types.listOf self.lib.type.overlay;
    default =
      if config.flake.overlays ? default
      then [ config.flake.overlays.default ]
      else [ ];
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
    type = lib.types.listOf lib.types.str;
    default = self.lib.defaults.systems;
    description = lib.literalMD ''
      Default list of systems in which to integrate.
    '';
  };
}
