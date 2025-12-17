{ self
, nixpkgs
, flakeModules
, specialArgs
, ...
}:

self.lib.factory.configurationModule {
  inherit specialArgs flakeModules nixpkgs;
  nixpkgsConfig = "nixosConfigurationNixpkgs";
  config = "nixosConfiguration";
}
