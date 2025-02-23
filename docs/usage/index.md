# Usage

This section describes how to use Perch to write flakes outputs in detail. This
chapter covers details that affect all flake outputs and how Perch imports
modules.

In the [introduction](../introduction.md), we used the `perch.lib.flake.make`
function. This function has the following arguments:

- `inputs`: These are your flake inputs. Perch uses this to set `specialArgs` to
  all of your modules. Perch also guarantees that these will be present even in
  other evaluation contexts like when another flake uses your modules or when a
  nixos module produced by a Perch module gets imported in a nixos
  configuration.
- `root`: This is the root of your flake. It is important to pass this argument
  along with `prefix` to import modules from a specific subdirectory of your
  flake. These two arguments are not one argument because of string contexts in
  nix. If you want to understand more about string contexts in nix and why this
  is important you can read more about it in the [nix string context documentation].
- `prefix`: This is the subdirectory from which Perch imports your modules as
  explained above with the `flake` argument.
- `selfModules`: This is a flat `attrset` of additional Perch modules you wish
  to evaluate to produce flake outputs. You can also use this argument to import
  all of your Perch modules in a controlled manner instead of relying on the
  `root` and `prefix` arguments. If so, you may want to read more about how
  [Perch imports modules](../api/import.nix).
- `inputModules`: This is a flat `list` of additional Perch modules you wish to
  add to the evaluation of your Perch modules.
- `includeInputModulesFromInputs`: Perch automatically sets the `perchModules`
  output of every flake that uses Perch. This allows Perch to also consume this
  output in consuming flakes. By default, Perch will use the default Perch
  module from all of your flake's inputs (if there are is any) in the evaluation
  of your own flake outputs. This allows Perch users to seamlessly add more
  outputs to their flake when using flakes that propagate flake outputs to
  consuming flakes (like the Perch flake does).

To better illustrate these arguments, the following is a nix flake that
effectively produces the same flake outputs as the
[introductory flake](../introduction.md).

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/<nixpkgs-version>";

    perch.url = "github:altibiz/perch/refs/tags/<perch-version>";
    perch.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { perch, ... } @inputs:
    perch.lib.flake.make {
      inherit inputs;
      selfModules = perch.lib.import.dirToFlatPathAttrs (./. + "flake");
      inputModules = [ perch.perchModules.default ];
      includeInputModulesFromInputs = false;
   };
}
```

The flake above uses the `perch.lib.import.dirToFlatPathAttrs` function to get a
flat `attrset` of name path pairs to your Perch modules in the flake
subdirectory of your repository. It is important to understand the flattening
aspect of this function to understand how the outputs of your flake will be
organized which is covered in the [naming section](#naming).

## Simple

If your flake is simple and you would like to put all of your flake in the
single `flake.nix` file, you can do so like this:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/<nixpkgs-version>";

    perch.url = "github:altibiz/perch/refs/tags/<perch-version>";
    perch.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { perch, ... } @inputs:
    perch.lib.flake.make {
      inherit inputs;
      selfModules.default = ({ ... }: {
        # ... your flake module goes here ...
      });
   };
}
```

## Naming

The formerly introduced `perch.lib.import.dirToFlatPathAttrs` function imports a
directory like this:

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

into an `attrset` like so:

```nix
{
  root1 = ./root/root1.nix;
  root2 = ./root/root2.nix;
  "leaf1/leaf11" = ./root/leaf1/leaf11.nix;
  "leaf1/leaf12" = ./root/leaf1/leaf12.nix;
  "leaf2/leaf21" = ./root/leaf2/leaf21.nix;
  "leaf2/leaf22" = ./root/leaf2/leaf22.nix;
  "leaf2/leaf23/leaf231" = ./root/leaf2/leaf23/leaf231.nix;
  "leaf2/leaf23/leaf232" = ./root/leaf2/leaf23/leaf232.nix;
  leafDefault = ./root/leafDefault/default.nix;
}
```

This impacts the way Perch names your flake outputs. For example, a package for
the `x86_64-linux` system defined in the `leaf2/leaf23/leaf231` module will be
present in the `packages."x86_64-linux"."leaf2/leaf23/leaf231"` flake output.

Essentially, Perch flattens the directory by introducing the slash character
between path segments and removing the file extensions to produce `attrset`
keys. Additionally, when a `default.nix` file is present inside of a directory,
Perch stops looking for files and directories inside of that directory.

## The following...

The following chapters describe how to create flake outputs using Perch. Each
flake output is covered in its own chapter.

[nix string context documentation]:
  https://nix.dev/manual/nix/stable/language/string-context
