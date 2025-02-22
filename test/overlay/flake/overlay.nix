{ super, pkgs, ... }:

{
  integrate.systems = [ "x86_64-linux" "x86_64-darwin" ];

  defaults.overlays.default = (final: prev: {
    myHello = final.writeShellApplication {
      name = "hello";
      runtimeInputs = [ prev.hello ];
      text = ''
        hello
      '';
    };
  });

  seal.defaults.nixosModule = "fizzbuzz";
  branch.nixosModule.nixosModule = {
    environment.systemPackages = [
      pkgs.myHello
    ];
  };

  seal.defaults.homeManagerModule = "fizzbuzz";
  branch.homeManagerModule.homeManagerModule = {
    home.packages = [
      pkgs.myHello
    ];
  };

  integrate.nixosConfiguration = {
    systems = [ "x86_64-linux" ];

    nixosConfiguration = {
      imports = [
        super.config.flake.nixosModules.default
      ];

      fileSystems."/" = {
        device = "/dev/disk/by-label/NIXROOT";
        fsType = "ext4";
      };

      boot.loader.grub.device = "nodev";

      system.stateVersion = "24.11";
    };
  };
}
