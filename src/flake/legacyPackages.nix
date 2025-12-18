{
  self,
  nixpkgs,
  flakeModules,
  specialArgs,
  ...
}:

self.lib.factory.artifactModule {
  inherit specialArgs flakeModules nixpkgs;
  nixpkgsConfig = "legacyPackageNixpkgs";
  config = "legacyPackage";
}
