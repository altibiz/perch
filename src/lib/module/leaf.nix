{ self, ... }:

{
  flake.lib.module.leaves =
    specialArgs:
    options:
    config:
    branch:
    modules:
    builtins.mapAttrs
      (_: module:
      self.lib.module.prune
        {
          inherit specialArgs;
          super = {
            inherit options config;
          };
        }
        branch
        module)
      modules;
}
