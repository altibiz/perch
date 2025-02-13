{
  description = "Perch";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.inputs.utils.follows = "flake-utils";
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
        dir = builtins.unsafeDiscardStringContext ./scripts/flake;
      };
    in
    libPart // flakePart;
}
