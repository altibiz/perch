{ lib, config, ... }:

{
  options.lib = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    description = lib.literalMD ''
      Create a `lib` flake output.
    '';
  };

  config.flake.lib = config.lib;
}
