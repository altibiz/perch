# Nixos configurations

Nixos configurations are declared via the `flake.nixosConfigurations` option.
Nixos configurations can also be declared via the
`integrate.nixosConfigurations` option if you want Perch to take care of
constructing `pkgs` for you. You can configure the default nixos configuration
via the `seal.defaults.nixosConfiguration` option for nixos configurations
configured via `integrate.nixosConfigurations`.

Perch allows you to create the effectively same nixos configuration for multiple
systems even though flake outputs don't allow for that. It does so by adding a
system suffix to your nixos configurations in the
`<nixos-configuration>-<system>` format.
