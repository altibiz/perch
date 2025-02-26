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

      integrateAttrset =
        if attrsetIntegrate ? ${integration}
        then attrsetIntegrate.${integration}
        else null;

      integrationSystems =
        if integrateAttrset == null
        then [ ]
        else if integrateAttrset ? systems
        then integrateAttrset.systems
        else integrateSystems;

      integrationNixpkgs =
        if integrateAttrset == null
        then { }
        else if integrateAttrset ? nixpkgs
        then integrateAttrset.nixpkgs
        else integrateNixpkgs;

      integrationNixpkgsOverlays =
        if integrationNixpkgs ? overlays
        then integrationNixpkgs.overlays
        else integrateNixpkgsOverlays;

      integrationNixpkgsConfig =
        if integrationNixpkgs ? config
        then integrationNixpkgs.config
        else integrateNixpkgsConfig;

      integrationAttrset =
        if integrateAttrset ? ${integration}
        then integrateAttrset.${integration}
        else null;

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
        (shallowlyIntegrateAttrset config integration)
          ((integrateAttrsetImports config integration)
            attrset))
        function
    else
      let
        attrset = imported;
      in
      (shallowlyIntegrateAttrset config integration)
        ((integrateAttrsetImports config integration)
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
