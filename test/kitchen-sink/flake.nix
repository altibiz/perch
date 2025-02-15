{
  outputs = { perch, ... }@inputs:
    perch.lib.loader.load {
      inherit inputs;
      root = ./.;
      prefix = "flake";
    };
}
