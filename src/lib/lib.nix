{ lib, ... }:

let
  node = other:
    lib.types.oneOf ([
      (lib.types.str)
      (lib.types.listOf lib.types.str)
      (lib.types.attrsOf lib.types.str)
      (lib.types.functionTo lib.types.raw)
    ] ++ other);

  nest = times:
    if times == 0
    then node [ ]
    else node [ (nest (times - 1)) ];
in
{
  options.flake.lib = lib.mkOption {
    type = nest 8;
    default = { };
    description = lib.literalMD ''
      `lib` flake output.
    '';
  };
}
