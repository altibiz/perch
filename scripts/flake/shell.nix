{ self, nixpkgs, ... } @rawInputs:

let
  mkImported = system:
    let
      pkgs = import nixpkgs { inherit system; };
      inputs = rawInputs // { inherit pkgs; };
    in
    self.lib.import.importDirWrap
      (import: import.__import.value inputs)
      "${self}/scripts/flake/shells";
in
{
  mkShells = system:
    let
      imported = mkImported system;
    in
    imported // { default = imported.dev; };
}
