{ self, lib, config, perchModules, ... }:

{
  options.branch.homeManagerModule =
    self.lib.option.mkBranchOption
      "homeManagerModule";

  options.propagate.homeManagerModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.deferredModule;
    default = { };
    description = lib.literalMD ''
      Propagated `homeManagerModules` flake output.
    '';
  };

  options.seal.defaults.homeManager = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = lib.literalMD ''
      The default `homeManagers` flake output.
    '';
  };

  config.propagate.homeManagerModules =
    let
      default = config.seal.defaults.homeManager;

      homeManagerModules =
        self.lib.module.leaves
          "homeManagerModule"
          perchModules.current;
    in
    if
      default != null
    then
      homeManagerModules // {
        default = homeManagerModules.${default};
      }
    else if
      homeManagerModules ? default
    then
      homeManagerModules
    else
      homeManagerModules // {
        default = {
          imports = builtins.attrValues homeManagerModules;
        };
      };
}
