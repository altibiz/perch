# Import

The `import` module contains functions that make it easy to import entire
directory hierarchies. The simples function is `perch.lib.import.importDir`
which imports a directory hierarchy like this:

```txt
| root
|   root1.nix
|   root2.nix
|
|---| leaf1
|   |   leaf11.nix
|   |   leaf12.nix
|
|---| leaf2
|   |   leaf21.nix
|   |   leaf22.nix
|   |
|   |---| leaf23
|       |   leaf231.nix
|       |   leaf232.nix
|
|---| leafDefault
    |   default.nix
```

into a nix object like so:

```nix
{
  root1 = import "root/root1.nix";
  root2 = import "root/root2.nix";
  leaf1 = {
    leaf11 = import "root/leaf1/leaf11.nix";
    leaf12 = import "root/leaf1/leaf12.nix";
  };
  leaf2 = {
    leaf21 = import "root/leaf2/leaf21.nix";
    leaf22 = import "root/leaf2/leaf22.nix";
    leaf23 = {
      leaf231 = import "root/leaf2/leaf23/leaf231.nix";
      leaf232 = import "root/leaf2/leaf23/leaf232.nix";
    };
  };
  leafDefault = import "root/leafDefault/default.nix";
}
```

. The function `perch.lib.import.importDirMeta` does the same thing but instead
of just importing the modules it returns an import object as such for each
module:

```nix
{
  __import = rec {
    path = "<path-to-module>";
    type = "<default-regular-or-unknown>";
    value = import path;
  };
}
```

. The function `perch.lib.import.importDirWrap` takes an additional first
argument that gets passed the same import object as the ones created by
`perch.lib.import.importDirMeta`.

An example of usage would be collecting all modules from a directory to pass to
`nixpkgs.lib.nixosSystem` as such:

```nix
{ nixpkgs, perch, ... }:

builtins.map
  (x: x.__import.value)
  (builtins.filter
    (x: x.__import.type == "regular" || x.__import.type == "default")
    (nixpkgs.lib.collect
      (builtins.hasAttr "__import")
      (perch.lib.import.importDirMeta "${self}/src/modules")));
```

In the example above, all modules in the `"${self}/src/modules"` directory will
be collected into a single list of modules ignoring unknown module types (files
that do not end in the `.nix` extension).
