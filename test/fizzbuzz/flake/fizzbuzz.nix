{ pkgs, super, ... }:

{
  integrate.systems = [ "x86_64-linux" "x86_64-darwin" ];

  seal.defaults.package = "fizzbuzz";
  integrate.package.package = pkgs.writeShellApplication {
    name = "hello";
    text = ''
      for i in {1..100}; do
        if (( i % 15 == 0 )); then
          echo "FizzBuzz"
        elif (( i % 3 == 0 )); then
          echo "Fizz"
        elif (( i % 5 == 0 )); then
          echo "Buzz"
        else
          echo "$i"
        fi
      done
    '';
  };

  seal.defaults.nixosModule = "fizzbuzz";
  branch.nixosModule.nixosModule = {
    environment.systemPackages = [
      super.config.flake.packages.${pkgs.system}.default
    ];
  };

  seal.defaults.homeManagerModule = "fizzbuzz";
  branch.homeManagerModule.homeManagerModule = {
    home.packages = [
      super.config.flake.packages.${pkgs.system}.default
    ];
  };

  integrate.nixosConfiguration = {
    systems = [ "x86_64-linux" ];

    nixosConfiguration = {
      imports = [
        super.config.flake.nixosModules.default
      ];

      fileSystems."/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
      };

      boot.loader.grub.device = "nodev";

      system.stateVersion = "24.11";
    };
  };
}
