{ self, lib, ... }:

{
  flake.lib.module.leaves =
    specialArgs:
    perchModules:
    options:
    config:
    branch:
    modules:
    let
      distill =
        self.lib.module.distill
          specialArgs
          perchModules
          options
          config
          (_: module: self.lib.module.patch
            (args: args // { pkgs = null; })
            (result: result)
            module)
          (_: lib.hasAttrByPath [ "branch" branch branch ])
          modules;
    in
    builtins.listToAttrs
      (builtins.map
        (name: {
          inherit name;
          value =
            self.lib.module.prune
              specialArgs
              branch
              modules.${name};
        })
        (builtins.attrNames distill));
}
