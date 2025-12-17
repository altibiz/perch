{ self
, lib
, nixpkgs
, flakeModules
, specialArgs
, ...
}:

self.lib.factory.artifactModule {
  inherit specialArgs flakeModules nixpkgs;
  nixpkgsConfig = "formatterNixpkgs";
  config = "formatter";
  artifactType = lib.types.attrsOf lib.types.raw;
  mapArtifacts = artifacts: builtins.listToAttrs
    (builtins.map
      ({ name, value }:
        {
          inherit name;
          # NOTE: a bit scary O.O
          value =
            (builtins.head
              (lib.attrsToList value)).value;
        })
      (lib.attrsToList artifacts));
}
