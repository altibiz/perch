{ lib, ... }:

{
  options.flake.lib = lib.mkOption {
    type = lib.types.attrsOf
      (lib.types.either
        (lib.types.functionTo lib.types.raw)
        (lib.types.attrsOf
          (lib.types.either
            (lib.types.functionTo lib.types.raw)
            lib.types.attrsOf)));
    default =
      { };
    description = lib.literalMD ''
      Create a `lib` flake output.
    '';
  };
}
