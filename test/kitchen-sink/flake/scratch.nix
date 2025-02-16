{ self
, perch
, perchModules
, derivedPerchModules
, allPerchModules
, lib
, pkgs
, ...
}:

{
  options.flake.scratch = lib.mkOption {
    type = lib.types.raw;
  };

  config.flake.scratch = {
    inherit
      self
      perch
      perchModules
      derivedPerchModules
      allPerchModules;
  };

  config.branches.system = {
    environment.systemPackages = [
      pkgs.hello
    ];
  };

  config.branches.home = {
    home.packages = [
      pkgs.hello
    ];
  };
}
