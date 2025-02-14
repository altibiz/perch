{
  description = "Perch";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
  };

  outputs =
    { self
    , nixpkgs
    , ...
    } @inputs:
    let
      libPart = {
        lib =
          nixpkgs.lib.mapAttrs'
            (name: value: { inherit name; value = value inputs; })
            (((import ./src/import.nix) inputs).importDir ./src);
      };

      flakePart = libPart.lib.flake.mkFlake {
        inherit inputs;
        dir = ./scripts/flake;
      };
    in
    libPart // flakePart;
}
