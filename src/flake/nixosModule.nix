{ self, lib, config, perchModules, ... }:

{
  options.branch.nixosModule =
    self.lib.option.mkBranchOption
      "nixosModule";

  options.propagate.nixosModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.deferredModule;
    default = { };
    description = lib.literalMD ''
      Propagated `nixosModules` flake output.
    '';
  };

  options.seal.defaults.nixosModule = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = lib.literalMD ''
      The default `nixosModules` flake output.
    '';
  };

  config.propagate.nixosModules =
    let
      default = config.seal.defaults.nixosModule;

      nixosModules =
        self.lib.module.leaves
          "nixosModule"
          perchModules.current;
    in
    if
      default != null
    then
      nixosModules // {
        default = nixosModules.${default};
      }
    else if
      nixosModules ? default
    then
      nixosModules
    else
      nixosModules // {
        default = {
          imports =
            builtins.attrValues
              nixosModules;
        };
      };
}
