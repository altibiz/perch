# Perch

Perch provides a structured framework for Nix flakes, offering a stable place to
organize, extend, and refine your configurations.

It does so by importing all nix files in a subdirectory of your repository and
interpreting them as perch modules which define your flake outputs.

<!-- markdownlint-disable MD013 -->

{{ #include ../README.md:6:27 }}

<!-- markdownlint-enable MD013 -->

This will interpret all nix files in the `./flake` subdirectory as perch modules
and produce a flake based off of them.

The [next chapter of this book](./getting-started.md) explains in more detail on
how to write perch modules.
