{ self, lib, perchModules, config, ... }:

{
  options.perchModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = lib.literalMD ''
      Create a `perchModules` flake output.
    '';
  };

  config.perchModules = perchModules;
  config.flake.perchModules = config.perchModules;
  config.lib.modules.load = { inputs, root, prefix }:
    let
      prefixedRoot = lib.path.append root prefix;
      perchModules = self.lib.imports.collect prefixedRoot;

      internalModule = rec {
        _file = ./modules.nix;
        key = _file;
        _module.args = {
          inherit perchModules;
        };
      };
    in
    lib.evalModules {
      class = "perch";
      specialArgs = inputs;
      modules = [ internalModule ] ++ perchModules;
    };
}
