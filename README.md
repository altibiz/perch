# Perch

Perch provides a structured framework for Nix flakes, offering a stable place to
organize, extend, and refine your configurations.

## Get started

Add the following to `flake.nix`:

```nix
{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";

    perch.url = "github:altibiz/perch/refs/tags/<perch-version>";
    perch.inputs.flake-utils.follows = "flake-utils";
    perch.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { perch, ... } @inputs:
    perch.lib.flake.mkFlake {
      inherit inputs;
      dir = "${self}/flake";
    };
}
```

## Documentation

Documentation can be found on [GitHub Pages](https://altibiz.github.io/perch/).

## Contributing

Please review
[CONTRIBUTING.md](https://github.com/altibiz/perch/blob/main/CONTRIBUTING.md)

## License

This project is licensed under the
[MIT License](https://github.com/altibiz/perch/blob/main/LICENSE.md).
