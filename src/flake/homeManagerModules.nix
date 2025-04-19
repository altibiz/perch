{ self
, lib
, specialArgs
, perchModules
, options
, config
, ...
}:

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

  options.seal.defaults.homeManagerModule = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = lib.literalMD ''
      The default `homeManagerModules` flake output.
    '';
  };

  config.propagate.homeManagerModules =
    let
      default = config.seal.defaults.homeManagerModule;

      homeManagerModules =
        self.lib.module.leaves
          specialArgs
          perchModules
          options
          config
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
