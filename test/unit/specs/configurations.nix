{ self, nixpkgs, ... }:

let
  makeConfigurations = self.lib.configurations.make;
  specialArgs = { inherit self; };
  config = "nixosConfiguration";
  nixpkgsConfig = "nixosConfigurationNixpkgs";
  defaultConfig = "defaultNixosConfiguration";
  flakeModules = {
    x68_64_Only = {
      nixosConfigurationNixpkgs = {
        system = "x86_64-linux";
      };
      nixosConfiguration = {
        fileSystems."/" = {
          device = "/dev/disk/by-label/NIX86";
          fsType = "ext4";
        };
        boot.loader.grub.device = "nodev";
        system.stateVersion = "24.11";
      };
    };
    allDefaultSystems = {
      nixosConfiguration = {
        fileSystems."/" = {
          device = "/dev/disk/by-label/NIXALL";
          fsType = "ext4";
        };
        boot.loader.grub.device = "nodev";
        system.stateVersion = "24.11";
      };
    };
  };

  configurations = makeConfigurations {
    inherit specialArgs flakeModules nixpkgs nixpkgsConfig config defaultConfig;
  };
in
{
  configurations_make_correct = configurations == {
    "allDefaultSystems-aarch64-darwin" = {
      fileSystems."/" = {
        device = "/dev/disk/by-label/NIXALL";
        fsType = "ext4";
      };
      boot.loader.grub.device = "nodev";
      system.stateVersion = "24.11";
    };
    "allDefaultSystems-aarch64-linux" = {
      fileSystems."/" = {
        device = "/dev/disk/by-label/NIXALL";
        fsType = "ext4";
      };
      boot.loader.grub.device = "nodev";
      system.stateVersion = "24.11";
    };
    "allDefaultSystems-x86_64-darwin" = {
      fileSystems."/" = {
        device = "/dev/disk/by-label/NIXALL";
        fsType = "ext4";
      };
      boot.loader.grub.device = "nodev";
      system.stateVersion = "24.11";
    };
    "x68_64_Only-x86_64-linux" = {
      fileSystems."/" = {
        device = "/dev/disk/by-label/NIX86";
        fsType = "ext4";
      };
      boot.loader.grub.device = "nodev";
      system.stateVersion = "24.11";
    };
    "allDefaultSystems-x86_64-linux" = {
      fileSystems."/" = {
        device = "/dev/disk/by-label/NIXALL";
        fsType = "ext4";
      };
      boot.loader.grub.device = "nodev";
      system.stateVersion = "24.11";
    };
  };
}
