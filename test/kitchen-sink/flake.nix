{
  outputs = { perch, ... }@inputs:
    perch.lib.flake.mkFlake {
      inherit inputs;
      root = ./.;
      prefix = "flake";
    };
}
