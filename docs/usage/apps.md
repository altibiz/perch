# Apps

Apps are declared via the `flake.apps` option. Apps can also be declared via the
`integrate.apps` option if you want Perch to take care of constructing `pkgs`
for you. By default, Perch converts all `flake.packages` outputs to `flake.apps`
using the `lib.getExe` function. You can disable this behaviour by setting the
`seal.defaults.packagesAsApps` to false.
