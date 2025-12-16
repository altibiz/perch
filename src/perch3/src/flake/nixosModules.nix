{ self
, flakeModules
, specialArgs
, ...
}:

self.lib.module.mkSubmoduleModule {
  inherit flakeModules specialArgs;
  config = "nixosModule";
}
