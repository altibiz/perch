{
  description = "Perch";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
  };

  outputs = { nixpkgs, ... } @inputs:
    let
      selflessInputs = builtins.removeAttrs inputs [ "self" ];

      specialArgs = (selflessInputs // {
        lib = nixpkgs.lib;
        self.lib = lib;
      });

      imports = (import ./src/imports.nix) specialArgs;

      configuration = nixpkgs.lib.evalModules {
        specialArgs = specialArgs;
        class = "perch";
        modules = imports.lib.imports.collect ./src;
      };

      lib = configuration.config.flake.lib;
    in
    lib.flake.make {
      inherit inputs;
      root = ./.;
      prefix = "src";
    };
}
