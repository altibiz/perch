{ self
, lib
, nixpkgs
, flakeModules
, specialArgs
, ...
}:

let
  nixpkgsConfig = "devShellNixpkgs";
  config = "devShell";
  configs = "${config}s";

  artifacts = self.lib.artifacts.make {
    inherit
      specialArgs
      flakeModules
      nixpkgs
      nixpkgsConfig
      config;
  };
in
{
  config.eval.allowedArgs = [ [ "pkgs" ] ];

  options.${configs} = lib.mkOption {
    type = lib.types.raw;
  };
  options.${nixpkgsConfig} = lib.mkOption {
    type = self.lib.type.nixpkgs.config;
  };
  config.eval.privateConfig = [ [ nixpkgsConfig ] [ config ] ];

  options.flake.${configs} = lib.mkOption {
    type = lib.types.attrsOf lib.types.raw;
    default = artifacts;
  };
  config.eval.publicConfig = [ [ "flake" configs ] ];
}

