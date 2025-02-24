# Defaults

You can set the default systems, nixpkgs config, and nixpkgs overlays for all
`integrate` prefix outputs via the `seal.defaults.systems`,
`seal.defaults.nixpkgs.config` and `seal.defaults.nixpkgs.overlays` options
respectively. If your flake has a `flake.overlays.default` output, it will be
used as the default singular value for the `seal.defaults.nixpkgs.overlays`
option.

These options can be overridden by setting `integrate.systems`,
`integrate.nixpkgs.config` or `integrate.nixpkgs.overlays` per Perch module.
These options can also be overridden per `integrate` prefix option. For example,
for the package of a Perch module, setting `integrate.package.systems`,
`integrate.package.nixpkgs.config` or `integrate.package.nixpkgs.overlays`.
