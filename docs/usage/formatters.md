# Formatters

The formatter is declared via the `flake.formatter` option. Formatters can also
be declared via the `integrate.formatters` option if you want Perch to take care
of constructing `pkgs` for you and also merge multiple formatters into a single
formatter using the nixpkgs `pkgs.writeShellApplication` and `lib.getExe`
functions.
