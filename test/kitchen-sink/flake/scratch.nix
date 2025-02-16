{ self
, perch
, perchModules
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
      perchModules;
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

  config.branches.configuration = {
    nixpkgs.hostPlatform.system = "x86_64-linux";
  };
}
