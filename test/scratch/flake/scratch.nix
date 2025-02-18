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

  config.integrate.systems = [ "x86_64-linux" ];

  config.integrate.nixosConfiguration = {
    nixosConfiguration = {
      fileSystems."/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
      };

      boot.loader.grub.device = "nodev";

      system.stateVersion = "24.11";

      environment.systemPackages = [
        pkgs.hello
      ];
    };
  };

  config.integrate.package = {
    systems = [ "x86_64-linux" "x86_64-darwin" ];

    package = pkgs.writeShellApplication {
      name = "hello";
      runtimeInputs = [ pkgs.hello ];
      text = "hello";
    };
  };

  config.integrate.check = {
    check = pkgs.writeShellApplication {
      name = "check";
      runtimeInputs = [ ];
      text = "exit 0";
    };
  };

  config.integrate.formatter = {
    formatter = pkgs.writeShellApplication {
      name = "formatter";
      runtimeInputs = [ ];
      text = "exit 0";
    };
  };

  config.integrate.devShell = {
    devShell = pkgs.mkShell {
      packages = [
        pkgs.hello
      ];
    };
  };
}
