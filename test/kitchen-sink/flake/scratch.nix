{ self
, perch
, perchModules
, derivedPerchModules
, allPerchModules
, lib
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
}
