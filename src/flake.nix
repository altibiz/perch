{ self, lib, ... }:

{
  config.flake.lib.flake.make = { inputs, root, prefix }:
    let
      prefixedRoot = lib.path.append root prefix;

      modules = self.lib.import.dirToPathList prefixedRoot;

      eval = self.lib.modules.eval {
        specialArgs = inputs;
        modules = modules;
      };
    in
    eval.config.flake;
}
