# API

This portion of the documentation describes the `lib` flake outputs of the Perch
flake. Perch also enables consuming flakes to create their own `lib` flake
outputs via the `flake.lib` option.

The `flake.lib` option type supports `attrsets` and `lists` that are up to 8
levels deep where the leaf types are booleans, numbers, strings, option types
and functions to raw values. This is so that the `flake.lib` option gets
correctly merged by the module system in the hopes that the 8 levels of depth
are sufficient. If this explanation is not sufficient please refer to the
[`lib.nix` file]

The following chapters describe the values of the `perch.lib` `attrset` per file
in the `src/lib` directory of this repository. The only exception to this is the
[`lib.nix` file] which is described in the paragraph above.

[`lib.nix` file]: https://github.com/altibiz/perch/blob/main/src/lib/lib.nix
