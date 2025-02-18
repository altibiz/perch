{ lib, ... }:

let
  nodeType = other:
    lib.types.oneOf ([
      (lib.types.str)
      (lib.types.listOf lib.types.str)
      (lib.types.functionTo lib.types.raw)
    ] ++ other);
in
{
  options.flake.lib = lib.mkOption {
    # NOTE: three levels deep is hopefully enough
    type =
      lib.types.attrsOf
        (nodeType [
          (lib.types.attrsOf
            (nodeType
              [
                (lib.types.attrsOf
                  (nodeType
                    [ ]))
              ]))
        ]);
    default =
      { };
    description = lib.literalMD ''
      `lib` flake output.
    '';
  };
}
