{ super, pkgs, ... }:

{
  flake.overlays.default = (final: prev: {
    myHello = final.writeShellApplication {
      name = "hello";
      runtimeInputs = [ prev.hello ];
      text = ''
        hello
      '';
    };
  });

  integrate.systems = [ "x86_64-linux" "x86_64-darwin" ];

  seal.defaults.nixosModule = "myHello";
  branch.nixosModule.nixosModule = {
    environment.systemPackages = [
      pkgs.myHello
    ];
  };

  seal.defaults.homeManagerModule = "myHello";
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
