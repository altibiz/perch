# Checks

Checks are declared via the `flake.checks` option. Checks can also be declared
via the `integrate.checks` option if you want Perch to take care of constructing
`pkgs` for you. You can configure the default check via the
`seal.defaults.check` option for checks configured via `integrate.checks`.
