{
  outputs = { perch, ... }@inputs:
    perch.lib.mkFlake {
      inherit inputs;
      root = ./.;
      prefix = "flake";
    };
}
