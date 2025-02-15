{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
    perch.url = "path:../..";
    perch.inputs.flake-utils.follows = "flake-utils";
    perch.inputs.nixpkgs.follows = "nixpkgs";
  };

  ouputs = { perch, ... }@inputs:
    perch.lib.mkFlake {
      inherit inputs;
      root = ./.;
      prefix = "flake";
    };
}
