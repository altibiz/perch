{ self, lib, ... }:

{
  lib.modules.load = { inputs, root, prefix }:
    let
      prefixedRoot = lib.path.append root prefix;
    in
    lib.evalModules {
      class = "perch";
      specialArgs = inputs;
      modules = self.lib.imports.collect prefixedRoot;
    };
}
