{ self, nixpkgs, nixt, lib, ... }:

let
  inputs = {
    inherit self nixpkgs nixt;
  };
in
let
  selflessInputs = builtins.removeAttrs inputs [ "self" ];

  specialArgs = (selflessInputs // {
    lib = nixpkgs.lib;
    self.lib3 = lib3;
  });

  importLib = ((import ./src/lib/import.nix) specialArgs).flake.lib3;

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
          (importLib.import.dirToFlatPathAttrs ./src));
  };

  lib3 = eval.config.flake.lib3;
in
{
  options.flake.perch3 = {
    type = lib.types.raw;
  };

  config.flake.perch3 = lib3.flake.make {
    inputs = specialArgs;
    root = ./.;
    prefix = "src";
  };
}
