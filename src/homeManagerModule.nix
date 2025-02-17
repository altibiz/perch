{ self, lib, ... }:

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
        self.lib.module.branch.artifacts
          "homeManagerModule";
    in
    if homeManagerModules ? default then homeManagerModules
    else homeManagerModules // {
      default = {
        imports = builtins.attrValues homeManagerModules;
      };
    };
}
