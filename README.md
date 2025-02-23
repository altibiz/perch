# Perch

Perch provides a structured framework for Nix flakes, offering a stable place to
organize, extend, and refine your configurations.

## Get started

Add the following to `flake.nix`:

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
      root = ./.;
      prefix = "flake";
    };
}
```

## Documentation

Documentation can be found on [GitHub Pages].

## Contributing

Please review [CONTRIBUTING.md](./CONTRIBUTING.md)

## License

This project is licensed under the [MIT License](./LICENSE.md).

[GitHub Pages]: https://altibiz.github.io/perch/
