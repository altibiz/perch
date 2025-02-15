{ self, nixpkgs, ... }:

{
  load = { inputs, root, prefix }:
    let
      prefixedRoot = nixpkgs.lib.path.append root prefix;

      modules =
        builtins.filter
          (module: module.__import.type == "regular"
            || module.__import.type == "default")
          (nixpkgs.lib.collect
            (builtins.hasAttr "__import")
            (self.lib.importDirMeta prefixedRoot));
    in
    nixpkgs.lib.evalModules {
      class = "perch";
      specialArgs = inputs;
      inherit modules;
    };
}
