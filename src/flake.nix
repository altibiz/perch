{ perchLib, lib, ... }:

{
  options.flake = lib.mkOption {
    type = lib.types.raw;
    default = { };
    description = lib.literalMD ''
      Create flake outputs.
    '';
  };

  config.lib.flake.make = { inputs, root, prefix }:
    let
      prefixedRoot = lib.path.append root prefix;
      modules = perchLib.import.dirToList prefixedRoot;

      eval = perchLib.lib.modules.eval {
        specialArgs = inputs;
        modules = modules;
      };
    in
    eval.config.flake;
}
