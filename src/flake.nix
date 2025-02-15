{ self, lib, ... }:

{
  config.flake.lib.flake.make = { inputs, root, prefix }:
    let
      prefixedRoot = lib.path.append root prefix;

      modules = self.lib.import.dirToFlatPathAttrs prefixedRoot;

      eval = self.lib.modules.eval {
        specialArgs = inputs;
        modules = modules;
      };
    in
    if eval.config ? flake
    then eval.config.flake
    else { };
}
