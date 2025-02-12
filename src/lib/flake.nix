{ self, nixpkgs, flake-utils, ... }:

let
  mkName = dir: path:
    builtins.replaceStrings
      [ "/" "\\" ]
      [ "." "." ]
      (nixpkgs.lib.removePrefix dir path);

  importNixWrapFlattenAttrs = wrap: dir:
    builtins.listToAttrs
      (builtins.map
        (module:
          let
            name = mkName dir module.__import.path;
          in
          {
            inherit name;
            value = wrap module;
          })
        (builtins.filter
          (module: module.__import.type == "regular"
            || module.__import.type == "default")
          (nixpkgs.lib.collect
            (builtins.hasAttr "__import")
            (self.lib.import.importDirMeta dir))));

  importNixWrapFlattenList = wrap: dir:
    (builtins.map wrap
      (builtins.filter
        (module: module.__import.type == "regular"
          || module.__import.type == "default")
        (nixpkgs.lib.collect
          (builtins.hasAttr "__import")
          (self.lib.import.importDirMeta dir))));

  mkImportedLib = inputs: dir:
    importNixWrapFlattenAttrs
      (module: module.__import.value inputs)
      dir;

  mkImportedApps = system: { nixpkgs
                           , pkgs ? (import nixpkgs { inherit system; })
                           }@inputs: dir:
    importNixWrapFlattenAttrs
      (module: {
        type = "app";
        program =
          pkgs.lib.getExe
            (pkgs.callPackage
              module.__import.value
              inputs);
      })
      dir;

  mkImportedPackages = system: { nixpkgs
                               , pkgs ? (import nixpkgs { inherit system; })
                               }@inputs: dir:
    importNixWrapFlattenAttrs
      (module:
        pkgs.callPackage
          module.__import.value
          inputs)
      dir;

  mkImportedShells =
    system: { nixpkgs
            , pkgs ? (import nixpkgs { inherit system; })
            }@inputs: dir:
    importNixWrapFlattenAttrs
      (module:
      pkgs.callPackage
        module.__import.value
        inputs)
      dir;

  mkImportedOverlays = inputs: dir:
    importNixWrapFlattenAttrs
      (module: module.__import.value inputs)
      dir;

  mkComposedOverlay = inputs: dir:
    nixpkgs.lib.composeManyExtensions
      (builtins.attrValues
        (mkImportedOverlays inputs dir));

  mkImportedChecks = system: { nixpkgs
                             , pkgs ? (import nixpkgs { inherit system; })
                             }@inputs: dir:
    importNixWrapFlattenAttrs
      (module:
        pkgs.callPackage
          module.__import.value
          inputs)
      dir;

  mkImportedFormatter = system: { nixpkgs
                                , pkgs ? (import nixpkgs { inherit system; })
                                }@inputs: dir:
    pkgs.writeShellApplication {
      name = "formatter";
      runtimeInputs = [ ];
      text = builtins.concatStringsSep
        "\n"
        (importNixWrapFlattenList
          (module:
            pkgs.lib.getExe
              (pkgs.callPackage
                module.__import.value
                inputs))
          dir);
    };

  mkImportedModules = isHome: inputs: dir:
    let
      imported =
        importNixWrapFlattenAttrs
          (module:
            (if isHome
            then self.lib.module.mkHomeManagerModule
            else self.lib.module.mkNixosModule)
              module.__import.value)
          dir;
    in
    imported // {
      default = {
        imports = builtins.attrValues imported;
        config = {
          nixpkgs.overlays = [ inputs.self.overlays.default ];
        } // (if isHome then {
          home.packages = builtins.attrValues inputs.self.packages;
        } else {
          system.environmentPackages = builtins.attrValues inputs.self.packages;
        });
      };
    };

  mkImportedHosts = { nixpkgs, home-manager ? null, ... }@inputs: users: dir:
    buil
      (module:
        if module.__import.type != "regular"
          && module.__import.type != "default"
        then null
        else
          let
            host = "${mkName dir module.__import.path}";

            specialArgs = inputs;

            shared = {
              options = {
                host = nixpkgs.lib.mkOption {
                  type = nixpkgs.lib.types.str;
                  default = host;
                  description = "Imported host name.";
                };
              };
            };
          in
          nixpkgs.lib.nixosSystem {
            inherit system specialArgs;
            modules = [
              shared
              (self.lib.module.mkNixosModule module.__import.value)
              inputs.self.nixosModules.default
              {
                networking.hostName = host;
                users.users = (builtins.listToAttrs
                  builtins.map
                  (user: {
                    name = user;
                    value = {
                      isNormalUser = true;
                      home = "/home/${user}";
                      createHome = true;
                    };
                  })
                  users);
              }

              (if home-manager == null then { } else {
                imports = [
                  home-manager.nixosModules.default
                ];
                home-manager.extraSpecialArgs = specialArgs;
                home-manager.users =
                  (builtins.listToAttrs
                    (builtins.map
                      (user: {
                        name = user;
                        value = {
                          options = {
                            user = nixpkgs.lib.mkOption {
                              type = nixpkgs.lib.types.str;
                              default = user;
                              description = "Imported user name.";
                            };
                          };

                          imports = [
                            shared
                            (self.lib.module.mkHomeManagerModule module.__import.value)
                            inputs.self.lib.homeManagerModules.default
                          ];
                        };
                      })
                      users));
              })
            ];
          })
      (importNixWrapFlattenAttrs
        dir);
in
{
  mkApps = { system, inputs, dir, default ? "default" }:
    let
      imported = mkImportedApps system inputs dir;
    in
    imported // { default = imported.${default}; };

  mkPackages = { system, inputs, dir, default ? "default" }:
    let
      imported = mkImportedPackages system inputs dir;
    in
    imported // { default = imported.${default}; };

  mkShells = { system, inputs, dir, default ? "default" }:
    let
      imported = mkImportedShells system inputs dir;
    in
    imported // { default = imported.${default}; };

  mkChecks = { system, inputs, dir }:
    mkImportedChecks system inputs dir;

  mkFormatter = { system, inputs, dir }:
    mkImportedFormatter system inputs dir;

  mkLib = { inputs, dir }:
    mkImportedLib inputs dir;

  mkOverlays = { inputs, dir }:
    (mkImportedOverlays inputs dir) // {
      default = mkComposedOverlay inputs dir;
    };

  mkNixosModules = { inputs, dir }:
    mkImportedModules
      false
      inputs
      dir;

  mkHomeManagerModules = { inputs, dir }:
    mkImportedModules
      true
      inputs
      dir;

  mkHosts = { inputs, dir }:
    mkImportedHosts
      inputs
      dir;
}

