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

  config.branches.nixosModule = {
    environment.systemPackages = [
      pkgs.hello
    ];
  };

  config.branches.homeManagerModule = {
    home.packages = [
      pkgs.hello
    ];
  };

  config.branches.nixosConfiguration = {
    nixpkgs.hostPlatform.system = "x86_64-linux";
  };

  config.seal.packages.scratch.function =
    ({ writeShellApplication, hello, ... }:
      writeShellApplication {
        name = "hello";
        runtimeInputs = [ hello ];
        text = "hello";
      });
}
