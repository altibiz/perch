# Legacy packages

Legacy packages are declared via the `flake.legacyPackages` option. Legacy
packages can also be declared via the `integrate.legacyPackages` option if you
want Perch to take care of constructing `pkgs` for you.

By default, Perch converts all `flake.packages` outputs to
`flake.legacyPackages` except the default package. You can disable this behavior
by setting the `seal.defaults.packagesAsLegacyPackages` to false.
