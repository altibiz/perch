{ lib, ... }:

{
  config.flake.lib.option.mkIntegrationOption =
    name:
    {
      systems = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = lib.literalMD ''
          Systems for which to build the `${name}s` flake output.
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

  config.flake.lib.option.mkBranchOption =
    name:
    lib.mkOption {
      type = lib.types.raw;
      default = { };
      description = lib.literalMD ''
        `${name}` flake output branch.
      '';
    };
}
