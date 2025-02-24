{ self, lib, ... }:

let
  integrateAttrsetImports =
    config:
    integration:
    attrset:
    self.lib.module.mapAttrsetImports
      (integrateImported config integration)
      attrset;

  shallowlyIntegrateAttrset =
    config:
    integration:
    attrset:
    let
      attrsetConfig =
        if attrset ? config
        then attrset.config
        else if attrset ? options
        then { }
        else attrset;

      attrsetIntegrate =
        if attrsetConfig ? integrate
        then attrsetConfig.integrate
        else { };

      integrateSystems =
        if attrsetIntegrate ? systems
        then attrsetIntegrate.systems
        else config.seal.defaults.systems;

      integrateNixpkgs =
        if attrsetIntegrate ? nixpkgs
        then attrsetIntegrate.nixpkgs
        else config.seal.defaults.nixpkgs;

      integrateNixpkgsOverlays =
        if integrateNixpkgs ? overlays
        then integrateNixpkgs.overlays
        else config.seal.defaults.nixpkgs.overlays;

      integrateNixpkgsConfig =
        if integrateNixpkgs ? config
        then integrateNixpkgs.config
        else config.seal.defaults.nixpkgs.config;

      integrationAttrset =
        if attrsetIntegrate ? ${integration}
        then attrsetIntegrate.${integration}
        else null;

      integrationSystems =
        if integrationAttrset == null
        then [ ]
        else if integrationAttrset ? systems
        then integrationAttrset.systems
        else integrateSystems;

      integrationNixpkgs =
        if integrationAttrset == null
        then { }
        else if integrationAttrset ? nixpkgs
        then integrationAttrset.nixpkgs
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
              value = integrationAttrset;
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
        (attrset:
        (integrateAttrsetImports config integration)
          ((shallowlyIntegrateAttrset config integration)
            attrset))
        function
    else
      let
        attrset = imported;
      in
      (integrateAttrsetImports config integration)
        ((shallowlyIntegrateAttrset config integration)
          attrset);
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
