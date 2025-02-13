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
      lib = nixpkgs.lib.mapAttrs'
        (name: value: { inherit name; value = value inputs; })
        (((import "${self}/src/import.nix") inputs).importDir "${self}/src");
    in
    (lib.flake.mkFlake {
      inherit inputs;
      dir = "${self}/scripts/flake";
    }) // {
      inherit lib;
    };
}
