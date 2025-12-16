{ self
, nixpkgs
, flakeModules
, specialArgs
, ...
}:

self.lib.module.mkArtifactModule {
  inherit specialArgs flakeModules nixpkgs;
  nixpkgsConfig = "appNixpkgs";
  config = "app";
}
