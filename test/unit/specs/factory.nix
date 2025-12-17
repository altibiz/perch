{ self, nixpkgs, ... }:

let
  submoduleResult = { specialArgs, flakeModules, ... }:
    self.lib.factory.submoduleModule {
      inherit specialArgs flakeModules;
      config = "nixosModule";
    };

  artifactResult = { specialArgs, nixpkgs, flakeModules, ... }:
    self.lib.factory.artifactModule {
      inherit specialArgs nixpkgs flakeModules;
      config = "package";
      nixpkgsConfig = "packageNixpkgs";
    };

  flakeResult = self.lib.flake.make {
    inputs = {
      inherit nixpkgs;
      input = {
        modules.default = {
          imports = [
            submoduleResult
            artifactResult
          ];
        };
      };
    };
    selfModules = {
      x86_64_Only = {
        nixosModule = { value = "x86_64 hello :)"; };
        defaultNixosModule = true;
        package = "x86_64 hello :)";
        packageNixpkgs.system = "x86_64-linux";
      };
      allDefaultSystems = {
        nixosModule = { value = "hello all default systems :)"; };
        package = "hello all default systems :)";
        defaultPackage = true;
      };
      none = { };
    };
  };
in
rec {
  factory_submodule_artifact_correct = (builtins.removeAttrs flakeResult [ "modules" ]) == {
    nixosModules = {
      allDefaultSystems = {
        value = "hello all default systems :)";
      };
      default = {
        value = "x86_64 hello :)";
      };
      x86_64_Only = {
        value = "x86_64 hello :)";
      };
    };
    packages = {
      aarch64-darwin = {
        default = "hello all default systems :)";
        allDefaultSystems = "hello all default systems :)";
      };
      aarch64-linux = {
        default = "hello all default systems :)";
        allDefaultSystems = "hello all default systems :)";
      };
      x86_64-darwin = {
        default = "hello all default systems :)";
        allDefaultSystems = "hello all default systems :)";
      };
      x86_64-linux = {
        default = "hello all default systems :)";
        allDefaultSystems = "hello all default systems :)";
        x86_64_Only = "x86_64 hello :)";
      };
    };
  };
  factory_submodule_correct = factory_submodule_artifact_correct;
  factory_artifact_correct = factory_submodule_artifact_correct;
}
