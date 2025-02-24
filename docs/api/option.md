# Option

- `option.mkBranchOption` (`name -> option`): Creates a flake output `branch`
  option.

- `option.mkIntegrationOption` (`config -> name -> attrset of option`): Creates
  a flake output `integrate` option. It also creates the appropriate systems,
  nixpkgs config and nixpkgs overlay options.
