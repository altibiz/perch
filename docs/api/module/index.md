# Module

The module directory contains files with functions that dictate the evaluation
of modules.

The `module.eval` function is a wrapper over the nixpkgs `lib.evalModules`
function. In addition to calling `lib.evalModules` with the modules from your
flake, modules from input flakes and special args it:

1. [exports](./export.md) modules from your flake and sets them to the
   `perchModules` flake output
2. [derives](./derive.md) modules from input flakes
3. [self-propagates](./self-propagate.md) modules from your flake
4. creates the `perchModules` module argument with the contents of:
   - `current`: self-propagated modules from your flake
   - `derived`: derived modules from input flakes
   - `all`: `current` ++ `derived`

The following chapters describe the files inside the directory except the
[`eval.nix` file] which is described in the paragraph above.

[`eval.nix` file]:
  https://github.com/altibiz/perch/blob/main/src/lib/module/eval.nix
