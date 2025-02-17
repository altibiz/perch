{ self, lib, perchModules, ... }:

{
  options.branch.homeManagerModule =
    self.lib.option.mkBranchOption
      "homeManagerModule";

  options.propagate.homeManagerModules = lib.mkOption {
    type =
      lib.types.attrsOf
        lib.types.deferredModule;
    default = { };
    description = lib.literalMD ''
      Propagated `homeManagerModules` flake output.
    '';
  };

  config.propagate.homeManagerModules =
    let
      homeManagerModules =
        self.lib.module.leaves
          "homeManagerModule"
          perchModules.current;
    in
    if homeManagerModules ? default then homeManagerModules
    else homeManagerModules // {
      default = {
        imports = builtins.attrValues homeManagerModules;
      };
    };
}
