# Overlays

Overlays are declared via the `flake.overlays` option. By default, Perch will
combine all overlays in `flake.overlays` into a single overlay via
`lib.composeManyExtensions` and set that as default. This behavior can be
disabled by setting the default overlay via `seal.defaults.overlay`.
