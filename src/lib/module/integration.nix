{ self, lib, ... }:

let
  integrateObjectImports =
    config:
    integration:
    object:
    self.lib.module.mapObjectImports
      (integrateImported config integration)
      object;

  shallowlyIntegrateObject =
    config:
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

      integrationConfig = {
        integrate = {
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
    config:
    integration:
    imported:
    if lib.isFunction imported
    then
      let
        function = imported;
      in
      self.lib.module.mapFunctionResult
        (object:
        (integrateObjectImports config integration)
          ((shallowlyIntegrateObject config integration)
            object))
        function
    else
      let
        object = imported;
      in
      (integrateObjectImports config integration)
        ((shallowlyIntegrateObject config integration)
          object);
in
{
  config.flake.lib.module.integrate =
    config:
    integration:
    module:
    (integrateImported config integration)
      (self.lib.module.importIfPath
        module);
}
