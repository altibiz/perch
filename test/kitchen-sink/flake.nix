{
  outputs = { perch, ... }@inputs:
    perch.lib.modules.load {
      inherit inputs;
      root = ./.;
      prefix = "flake";
    };
}
