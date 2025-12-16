{ self, nixpkgs, nixt, ... }:

let
  inputs = {
    inherit self nixpkgs nixt;
  };
in
let
  selflessInputs = builtins.removeAttrs inputs [ "self" ];

  specialArgs = (selflessInputs // {
    lib = nixpkgs.lib;
    self.lib = lib;
  });

  importLib = ((import ./src/lib/import.nix) specialArgs).flake.lib;

  # NOTE: it is important to be mindful of this eval context
  # this context makes it wrong to request anything that
  # isn't a function inside of library modules
  #
  # this is because to avoid infinite recusion we need to first
  # get all the functions from perch and then create the flake
  # with these functions
  #
  # in order to do that not a single function module can request
  # anything related to self that is also not a library function
  #
  # because of that these functions get evaluated
  # in this stripped down eval context
  eval = nixpkgs.lib.evalModules {
    specialArgs = specialArgs;
    class = "flake";
    modules =
      builtins.attrValues
        (nixpkgs.lib.filterAttrs
          (name: _: nixpkgs.lib.hasPrefix "lib" name)
          (importLib.import.dirToFlatPathAttrs "-" ./src));
  };

  lib = eval.config.flake.lib;
in
{
  options.flake.perch3 = nixpkgs.lib.mkOption {
    type = nixpkgs.lib.types.raw;
  };

  config.flake.perch3 = lib.flake.make {
    inputs = specialArgs;
    root = ./.;
    prefix = "src";
  };
}
