{
  self,
  nixpkgs,
  flakeModules,
  specialArgs,
  ...
}:

self.lib.factory.artifactModule {
  inherit specialArgs flakeModules nixpkgs;
  nixpkgsConfig = "appNixpkgs";
  config = "app";
}
