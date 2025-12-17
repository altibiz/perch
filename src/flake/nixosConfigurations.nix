{ self
, lib
, nixpkgs
, flakeModules
, specialArgs
, ...
}:

self.lib.factory.artifactModule {
  inherit specialArgs flakeModules nixpkgs;
  nixpkgsConfig = "nixosConfigurationNixpkgs";
  config = "nixosConfiguration";
  artifactType = lib.types.attrsOf lib.types.raw;
  mapArtifacts = artifacts: builtins.listToAttrs
    (lib.flatten
      (builtins.map
        ({ name, value }:
          let
            system = name;
            configs = value;
          in
          builtins.map
            ({ name, value }: {
              inherit value;
              name = "${name}-${system}";
            })
            (lib.attrsToList configs))
        (lib.attrsToList artifacts)));
}
