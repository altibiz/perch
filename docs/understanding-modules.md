# Understanding modules

Perch modules are like nixos modules but instead of configuring different
aspects of a nixos system, Perch modules configure different outputs of a nix
flake.

Here is an example implementation of a
[Fizz buzz](https://en.wikipedia.org/wiki/Fizz_buzz) Perch module:

<!-- markdownlint-disable MD013 -->

```nix
{{ #include ../test/fizzbuzz/flake/fizzbuzz.nix }}
```

<!-- markdownlint-enable MD013 -->

This example contains a lot of different parts so lets analyze it line-by-line:

1. Systems which support our Fizz buzz implementation are declared
2. The Fizz buzz package is created and it is set as the default package for the
   flake
3. The nixos module is created and it is set as the default nixos module for the
   flake
4. A minimal nixos configuration is created only supporting the `x86_64-linux`
   system

To the experienced nix users this might be obvious so lets break down how Perch
does this a bit further.

## Flake, seal, propagate, branch and integrate

The `flake`, `seal`, `propagate`, `branch` and `integrate` option prefixes are
special prefixes that tell Perch how to treat the options and config inside.

- `flake`: These are the flake outputs. This prefix gets evaluated directly by
  Perch to produce a flake. However, if another flake uses your Perch module,
  the options and config under this prefix will be removed. This is kind of like
  the nixpkgs `lib.mkForce` function in reverse but with more isolation. By
  doing this we are telling Perch that these options and config are internal to
  our flake.
- `seal`: This prefix tells Perch not to propagate these options to flakes that
  would use our module. This is useful because we might want `fizzbuzz` to be
  the default package in our flake but consuming flakes might set it to
  something else. In this regard, this prefix is similar to the `flake` prefix
  but it does not produce any flake outputs.
- `propatate`: This prefix tells Perch to treat options and config under it as
  options and config to be propagated to consuming flakes. This allows other
  flakes (not just Perch) to create flake outputs for consuming flakes.
- `branch`: This prefix tells Perch that in certain contexts, these options and
  config will be the result of pruning our modules. Module pruning allows us to
  then takes these options and config and create modules with only these options
  and config. In the example above, Perch will create a nixos module from the
  Perch module via the `branch.nixosModule.nixosModule` attribute.
- `integrate`: This prefix is similar to the `branch` prefix, but on top of
  branching, it tells Perch that these options and config will also be
  integrated in the specified systems. Integration means that Perch will
  construct `pkgs` instances based on the specified systems and evaluate the
  pruned module attribute to get the value it provides.

## Super

You may have noticed that configuration under the `branch` and `integrate`
prefixes uses a special argument called `super`. This special argument is needed
because the configuration under these prefixes gets evaluated in a different
context than our module.

In the Fizz buzz example above, the nixos module gets evaluated when it is used
in a nixos configuration, and the Fizz buzz package and nixos configuration get
evaluated in its own context with `pkgs` present. This is useful because it
takes care of the systems, nixpkgs configuration and overlays in a modular
manner.

Now, because this configuration gets evaluated in a different context, the
evaluation context has a different set of options and config. This is where
`super` comes in. In the example above, the nixos configuration in isolation may
look like a regular nixos configuration, being able to access regular nixos
configuration options and config, but it is able to access options and config
from the flake options and config such as the Fizz buzz default nixos module
(the one defined right above in the same Perch module) via
`super.config.flake.nixosModules.default`.

## What's next?

From this point on, you should be fairly accustomed to Perch modules and most
users shouldn't need to dig much deeper. You should also read more about general
usage and the various flake outputs Perch allows you to produce in the
[Usage](./usage/index.md) section. If you want to create any kind of flake that
uses the `integrate` prefix outputs, it is advised that you also read about
[defaults](./usage/defaults.md).

For reusable Perch module authors (those of you who want to provide flake
outputs for consuming flakes), however, it is advised you read about the
[API](./api/index.md). For examples, please refer to the [Perch
`src/flake` directory].

[Perch `src/flake` directory]:
  https://github.com/altibiz/perch/blob/main/src/flake
