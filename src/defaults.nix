{ self, lib, flake-utils, ... }:

{
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
    default = flake-utils.lib.defaultSystems;
    description = lib.literalMD ''
      Default list of systems in which to integrate.
    '';
  };
}
