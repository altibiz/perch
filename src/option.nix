{ self, lib, ... }:

{
  config.flake.lib.option.mkBranchOption =
    name:
    lib.mkOption {
      type = lib.types.raw;
      default = { };
      description = lib.literalMD ''
        `${name}` flake output branch.
      '';
    };

  config.flake.lib.option.mkIntegrationOption =
    config:
    name: {
      systems = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = lib.literalMD ''
          List of systems in which to integrate.
        '';
      };

      nixpkgs.overlays = lib.mkOption {
        type = lib.types.raw;
        default = config.seal.defaults.nixpkgs.overlays;
        description = lib.literalMD ''
          Nixpkgs overlays of systems in which to integrate.
        '';
      };

      nixpkgs.config = lib.mkOption {
        type = self.lib.type.nixpkgs.config;
        default = config.seal.defaults.nixpkgs.config;
        description = lib.literalMD ''
          Nixpkgs config of systems in which to integrate.
        '';
      };

      ${name} = lib.mkOption {
        type = lib.types.raw;
        default = null;
        description = lib.literalMD ''
          `${name}s` flake output.
        '';
      };
    };
}
