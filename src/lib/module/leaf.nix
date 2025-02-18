{ self, ... }:

{
  flake.lib.module.leaves =
    branch:
    modules:
    builtins.mapAttrs
      (_: module:
      self.lib.module.prune branch module)
      modules;
}
