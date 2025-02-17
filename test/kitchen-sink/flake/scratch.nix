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

  config.branch.nixosModule = {
    environment.systemPackages = [
      pkgs.hello
    ];
  };

  config.branch.homeManagerModule = {
    home.packages = [
      pkgs.hello
    ];
  };

  config.integrate.nixosConfiguration = {
    systems = [ "x86_64-linux" ];

    module = {
      environment.systemPackages = [
        pkgs.hello
      ];
    };
  };

  config.integrate.package = {
    systems = [ "x86_64-linux" ];

    package = pkgs.writeShellApplication {
      name = "hello";
      runtimeInputs = [ pkgs.hello ];
      text = "hello";
    };
  };
}
