# Dev shells

Dev shells are declared via the `flake.devShells` option. Dev shells can also be
declared via the `integrate.devShells` option if you want Perch to take care of
constructing `pkgs` for you. You can configure the default dev shell via the
`seal.defaults.devShell` option for dev shells configured via
`integrate.devShells`.
