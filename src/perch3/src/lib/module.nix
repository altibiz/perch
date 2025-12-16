{ lib, self, ... }:

let
  patchAttrsetImports =
    mapArgsDeclaration:
    mapArgsDefinition:
    mapResult:
    attrset:
    self.lib.trivial.mapAttrsetImports
      (patchImported
        mapArgsDeclaration
        mapArgsDefinition
        mapResult)
      attrset;

  patchImported =
    mapArgsDeclaration:
    mapArgsDefinition:
    mapResult:
    imported:
    if lib.isFunction imported
    then
      let
        function = imported;
      in
      self.lib.trivial.mapFunctionArgs
        mapArgsDeclaration
        mapArgsDefinition
        (self.lib.trivial.mapFunctionResult
          (function: attrset: mapResult
            function
            (patchAttrsetImports
              mapArgsDeclaration
              mapArgsDefinition
              mapResult
              attrset))
          function)
    else
      mapResult
        imported
        (patchAttrsetImports
          mapArgsDeclaration
          mapArgsDefinition
          mapResult
          imported);
in
{
  flake.lib.module.patch =
    mapArgsDeclaration:
    mapArgsDefinition:
    mapResult:
    module:
    patchImported
      mapArgsDeclaration
      mapArgsDefinition
      mapResult
      (self.lib.trivial.importIfPath
        module);

  flake.lib.module.mkSubmoduleModule =
    { flakeModules
    , specialArgs
    , config
    }:
    let
      configs = "${config}s";

      submodules = self.lib.submodules.make {
        inherit flakeModules specialArgs config;
      };
    in
    {
      options.${config} = lib.mkOption {
        type = lib.types.attrsOf lib.types.raw;
      };
      config.eval.privateConfig = [ [ config ] ];

      options.flake.${configs} = lib.mkOption {
        type = lib.types.attrsOf lib.types.raw;
        default =
          submodules // {
            default = {
              imports = builtins.attrValues submodules;
            };
          };
      };
      config.eval.publicConfig = [ [ "flake" configs ] ];
    };

  flake.lib.module.mkArtifactModule =
    { flakeModules
    , specialArgs
    , nixpkgs
    , nixpkgsConfig
    , config
    }:
    let
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
    };
}
