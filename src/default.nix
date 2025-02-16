{ self, lib, ... }:

{
  options.seal.defaults.nixpkgs.config = lib.mkOption {
    type = self.lib.type.nixpkgs.config;
    default = { };
    description = lib.literalMD ''
      Nixpkgs config used for defaults in flake outputs.
    '';
  };
}
