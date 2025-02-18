{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
  };

  outputs = { nixpkgs, ... } @inputs:
    let
      selflessInputs = builtins.removeAttrs inputs [ "self" ];

      specialArgs = (selflessInputs // {
        lib = nixpkgs.lib;
        self.lib = lib;
      });

      importLib = ((import ./src/import.nix) specialArgs).flake.lib;

      eval = nixpkgs.lib.evalModules {
        specialArgs = specialArgs;
        class = "perch";
        modules =
          builtins.attrValues
            (nixpkgs.lib.filterAttrs
              (name: _:
                !(nixpkgs.lib.hasPrefix "dev" name)
                && !(nixpkgs.lib.hasPrefix "flake" name))
              (importLib.import.dirToFlatPathAttrs ./src));
      };

      lib = eval.config.flake.lib;
    in
    lib.flake.make {
      inputs = specialArgs;
      root = ./.;
      prefix = "src";
    };
}
