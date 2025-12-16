{ self
, nixpkgs
, flakeModules
, specialArgs
, ...
}:

self.lib.module.mkArtifactModule {
  inherit specialArgs flakeModules nixpkgs;
  nixpkgsConfig = "legacyPackageNixpkgs";
  config = "legacyPackage";
}
