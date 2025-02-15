{ self, nixpkgs, ... }:

{
  load = { inputs, root, prefix }:
    let
      prefixedRoot = nixpkgs.lib.path.append root prefix;

      modules =
        builtins.map
          (module: module.__import.value)
          (builtins.filter
            (module: module.__import.type == "regular"
              || module.__import.type == "default")
            (nixpkgs.lib.collect
              (builtins.hasAttr "__import")
              (self.lib.import.importDirMeta prefixedRoot)));
    in
    nixpkgs.lib.evalModules {
      class = "perch";
      specialArgs = inputs;
      modules = modules;
    };
}
