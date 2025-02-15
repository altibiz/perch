{ lib, perchModules ? [ ], ... }:

{
  options.flake.perchModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = lib.literalMD ''
      Create a `perchModules` flake output.
    '';
  };

  config.flake.perchModules = perchModules;
  config.flake.lib.modules.eval = { specialArgs, modules }:
    let
      internalModule = {
        config._module.args = {
          perchModules = modules;
        };
      };
    in
    lib.evalModules {
      class = "perch";
      inherit specialArgs;
      modules = [ internalModule ] ++ modules;
    };
}
