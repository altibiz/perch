{ self, lib, ... }:

{
  options.flake = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    description = lib.literalMD ''
      Create flake outputs.
    '';
  };

  config.lib.flake.make = { inputs, root, prefix }:
    let
      configuration = self.lib.modules.load {
        inherit inputs root prefix;
      };
    in
    configuration.config.flake;
}
