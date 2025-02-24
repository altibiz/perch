# Nixos modules

Nixos modules are declared via the `flake.nixosModules` option. Nixos modules
can also be declared via the `branch.nixosModule` option if you want Perch to
take care of module pruning for you. You can configure the default nixos module
via the `seal.defaults.nixosModule` option for nixos modules configured via
`branch.nixosModules`.
