{ self, lib, ... }:

{
  options.branch.nixosModule =
    self.lib.option.mkBranchOption
      "nixosModule";

  options.propagate.nixosModules = lib.mkOption {
    type =
      lib.types.attrsOf
        lib.types.deferredModule;
    default = { };
    description = lib.literalMD ''
      Propagated `nixosModules` flake output.
    '';
  };

  config.propagate.nixosModules =
    let
      nixosModules =
        self.lib.module.branch.artifacts
          "nixosModule";
    in
    if nixosModules ? default then nixosModules
    else nixosModules // {
      default = {
        imports =
          builtins.attrValues
            nixosModules;
      };
    };
}
