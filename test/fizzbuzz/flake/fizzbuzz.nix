{ self, pkgs, lib, config, ... }:

{
  integrate.systems = [ "x86_64-linux" "x86_64-darwin" ];

  seal.defaults.package = "fizzbuzz";
  integrate.package.package = pkgs.writeShellApplication {
    name = "fizzbuzz";
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
    options.programs.fizzbuzz = {
      enable = lib.mkEnableOption "fizzbuzz";
    };

    config = lib.mkIf config.programs.fizzbuzz.enable {
      environment.systemPackages = [
        self.packages.${pkgs.system}.default
      ];
    };
  };

  seal.defaults.homeManagerModule = "fizzbuzz";
  branch.homeManagerModule.homeManagerModule = {
    options.programs.fizzbuzz = {
      enable = lib.mkEnableOption "fizzbuzz";
    };

    config = lib.mkIf config.programs.fizzbuzz.enable {
      home.packages = [
        self.packages.${pkgs.system}.default
      ];
    };
  };

  integrate.nixosConfiguration = {
    systems = [ "x86_64-linux" ];

    nixosConfiguration = {
      imports = [
        self.nixosModules.default
      ];

      fileSystems."/" = {
        device = "/dev/disk/by-label/NIXROOT";
        fsType = "ext4";
      };

      boot.loader.grub.device = "nodev";

      programs.fizzbuzz.enable = true;

      system.stateVersion = "24.11";
    };
  };
}
