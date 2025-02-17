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

      integrationConfig =
        {
          ${integration} = {
            systems = integrationSystems;
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
          (args:
          args
          // specialArgs
          // {
            inherit trunkArgs;
          })
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
  flake.lib.module.integrate =
    integration:
    module:
    (integrateImported integration)
      (self.lib.module.importIfPath
        module);
}
