{ self, ... }:

let
  makeFlake = self.lib3.flake.make;

  inputs = {
    perch = self // {
      modules.default = {
        imports = [
          ({ perch, lib, flakeModules, ... }:
            let
              nixosModules = builtins.mapAttrs
                (perch.lib3.module.patch
                  (_: args: args)
                  (_: args: args)
                  (_: result:
                    if result ? nixosModule
                    then result.nixosModule
                    else if result ? config
                    then
                      if result.config ? nixosModule
                      then result.config.nixosModule
                      else { }
                    else { }))
                flakeModules;
            in
            {
              options.nixosModule = lib.mkOption {
                type = lib.types.attrsOf lib.types.raw;
              };
              config.eval.privateConfig = [ [ "nixosModule" ] ];
              config.flake.nixosModules = nixosModules // {
                default = {
                  imports = builtins.attrValues nixosModules;
                };
              };
            })
        ];
      };
    };
  };

  selfModules = {
    module = {
      nixosModule = {
        environment.systemPackages = [ "my package" ];
      };
    };
  };

  result = makeFlake { inherit inputs selfModules; };
in
{
  flake_make_result_correct = result.flake.nixosModules == {
    module = {
      environment.systemPackages = [ "my package" ];
    };
    default = {
      imports = [
        {
          environment.systemPackages = [ "my package" ];
        }
      ];
    };
  };
}
