# Export

- `module.export` (`specialArgs -> module -> module`): Strips the module and its
  imports of `flake`, `seal`, `branch`, and `integrate` prefixes and ensures
  that the `specialArgs` will be merged into the module arguments any time it is
  called if it's a function module
