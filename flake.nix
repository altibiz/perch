{
  description = "Perch";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
  };

  outputs =
    { self
    , flake-utils
    , nixpkgs
    , ...
    } @ rawInputs:
    let
      inputs = rawInputs;

      libPart = {
        lib = nixpkgs.lib.mapAttrs'
          (name: value: { inherit name; value = value inputs; })
          (((import "${self}/src/lib/import.nix") inputs).importDir "${self}/src/lib");
      };

      systemPart = flake-utils.lib.eachDefaultSystem (system:
        let
          flake = self.lib.import.importDirWrap
            (import: import.__import.value inputs)
            "${self}/scripts/flake";
        in
        {
          devShells = flake.shell.mkShells system;
          formatter = flake.formatter.mkFormatter system;
          checks = flake.check.mkChecks system;
        });
    in
    libPart // systemPart;
}
