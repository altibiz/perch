{
  description = "Perch";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
  };

  # WARNING: don't touch this
  # it easily devolves into infinite recursion
  outputs = { nixpkgs, ... } @inputs:
    let
      selflessInputs = builtins.removeAttrs inputs [ "self" ];

      specialArgs = (selflessInputs // {
        lib = nixpkgs.lib;
        perchLib = lib;
      });


      eval = nixpkgs.lib.evalModules {
        specialArgs = specialArgs;
        class = "perch";
        modules = ((import ./src/imports.nix) specialArgs).lib.import.dirToList ./src;
      };

      lib = eval.config.flake.lib;
    in
    lib.flake.make {
      inherit inputs;
      root = ./.;
      prefix = "src";
    };
}
