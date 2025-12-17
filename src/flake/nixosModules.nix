{ self
, flakeModules
, specialArgs
, ...
}:

self.lib.factory.submoduleModule {
  inherit flakeModules specialArgs;
  config = "nixosModule";
}
