{ config, self, lib, specialArgs, ... }@trunkArgs:

let

  integrateObjectImports =
    integrate:
    object:
    self.lib.module.mapObjectImports
      (integrateImported
        integrate)
      object;

  shallowlyIntegrateObject =
    integration:
    object:
    let
      objectConfig =
        if object ? config
        then object.config
        else if object ? options
        then { }
        else object;

      objectIntegrate =
        if objectConfig ? integrate
        then objectConfig.integrate
        else { };

      integrateSystems =
        if objectIntegrate ? systems
        then objectIntegrate.systems
        else config.seal.defaults.systems;

      integrateNixpkgs =
        if objectIntegrate ? nixpkgs
        then objectIntegrate.nixpkgs
        else config.seal.defaults.nixpkgs;

      integrateNixpkgsOverlays =
        if integrateNixpkgs ? overlays
        then integrateNixpkgs.overlays
        else config.seal.defaults.nixpkgs.overlays;

      integrateNixpkgsConfig =
        if integrateNixpkgs ? config
        then integrateNixpkgs.config
        else config.seal.defaults.nixpkgs.config;

      integrationObject =
        if objectIntegrate ? ${integration}
        then objectIntegrate.${integration}
        else null;

      integrationSystems =
        if integrationObject == null
        then [ ]
        else if integrationObject ? systems
        then integrationObject.systems
        else integrateSystems;

      integrationNixpkgs =
        if integrationObject == null
        then { }
        else if integrationObject ? nixpkgs
        then integrationObject.nixpkgs
        else integrateNixpkgs;

      integrationNixpkgsOverlays =
        if integrationNixpkgs ? overlays
        then integrationNixpkgs.overlays
        else integrateNixpkgsOverlays;

      integrationNixpkgsConfig =
        if integrationNixpkgs ? config
        then integrationNixpkgs.config
        else integrateNixpkgsConfig;

      integrationConfig =
        {
          ${integration} = {
            systems = integrationSystems;
            nixpkgs.overlays = integrationNixpkgsOverlays;
            nixpkgs.config = integrationNixpkgsConfig;
          }
          // (builtins.listToAttrs
            (builtins.map
              (system: {
                name = system;
                value = integrationObject;
              })
              integrationSystems));
        };
    in
    integrationConfig;

  integrateImported =
    integration:
    imported:
    if lib.isFunction imported
    then
      let
        function = imported;
      in
      self.lib.module.mapFunctionResult
        (object:
        (integrateObjectImports integration)
          ((shallowlyIntegrateObject integration)
            object))
        (self.lib.module.mapFunctionArgs
          (args: args
            // specialArgs
            // { inherit trunkArgs; })
          function)
    else
      let
        object = imported;
      in
      (integrateObjectImports integration)
        ((shallowlyIntegrateObject integration)
          object);
in
{
  options.integrate.systems = lib.mkOption {
    type =
      lib.types.listOf
        lib.types.str;
    default = config.seal.defaults.systems;
    description = lib.literalMD ''
      List of systems in which to integrate.
    '';
  };

  options.integrate.nixpkgs.overlays = lib.mkOption {
    type =
      lib.types.listOf
        lib.types.str;
    default = config.seal.defaults.nixpkgs.overlays;
    description = lib.literalMD ''
      List of systems in which to integrate.
    '';
  };

  options.integrate.nixpkgs.config = lib.mkOption {
    type =
      lib.types.listOf
        lib.types.str;
    default = config.seal.defaults.nixpkgs.config;
    description = lib.literalMD ''
      List of systems in which to integrate.
    '';
  };

  config.flake.lib.module.integrate =
    integration:
    module:
    (integrateImported integration)
      (self.lib.module.importIfPath
        module);
}
