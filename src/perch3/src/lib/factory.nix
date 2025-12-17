{ lib, self, ... }:

{
  flake.lib.factory.submoduleModule =
    { flakeModules
    , specialArgs
    , config
    , submoduleType ? lib.types.attrsOf lib.types.raw
    , mapSubmodules ? (_: _)
    }:
    let
      configs = "${config}s";

      submodules = mapSubmodules (self.lib.submodules.make {
        inherit flakeModules specialArgs config;
      });
    in
    {
      options.${config} = lib.mkOption {
        type = lib.types.attrsOf lib.types.raw;
      };
      config.eval.privateConfig = [ [ config ] ];

      options.flake.${configs} = lib.mkOption {
        type = submoduleType;
        default =
          submodules // {
            default = {
              imports = builtins.attrValues submodules;
            };
          };
      };
      config.eval.publicConfig = [ [ "flake" configs ] ];
    };

  flake.lib.factory.artifactModule =
    { flakeModules
    , specialArgs
    , nixpkgs
    , nixpkgsConfig
    , config
    , artifactType ? lib.types.attrsOf (lib.types.attrsOf lib.types.raw)
    , mapArtifacts ? (_: _)
    }:
    let
      configs = "${config}s";
      defaultConfig = "default${self.lib.string.capitalize config}";

      artifacts = mapArtifacts (self.lib.artifacts.make {
        inherit
          specialArgs
          flakeModules
          nixpkgs
          nixpkgsConfig
          defaultConfig
          config;
      });
    in
    {
      config.eval.allowedArgs = [ "pkgs" ];

      options.${defaultConfig} = lib.mkOption {
        type = lib.types.boolean;
        default = false;
      };
      options.${config} = lib.mkOption {
        type = lib.types.raw;
      };
      options.${nixpkgsConfig} = lib.mkOption {
        type = self.lib.type.nixpkgs.config;
      };
      config.eval.privateConfig = [ [ nixpkgsConfig ] [ config ] [ defaultConfig ] ];

      options.flake.${configs} = lib.mkOption {
        type = artifactType;
        default = artifacts;
      };
      config.eval.publicConfig = [ [ "flake" configs ] ];
    };
}
