{ self, nixpkgs, flake-utils, ... }:

let
  mkName = dir: path:
    nixpkgs.removeSuffix
      ".default"
      (nixpkgs.lib.removePrefix
        "."
        (builtins.replaceStrings
          [ "/" "\\" ]
          [ "." "." ]
          (nixpkgs.lib.removePrefix
            dir
            (nixpkgs.lib.removeSuffix
              ".nix"
              path))));

  extractAttr = module: attr: default:
    let
      attrset =
        if builtins.isAttrs module
        then module
        else if builtins.isFunction module
        then
          let
            args =
              builtins.listToAttrs
                (builtins.map
                  (name: { inherit name; value = null; })
                  (builtins.attrNames
                    (builtins.functionArgs module)));
          in
          (module args)
        else { };
    in
    if builtins.hasAttr attr attrset
    then attrset.${attr}
    else default;

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

  mkModules = isHome: inputs: dir:
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
in
{
  mkShells = { system, inputs, dir }:
    let
      mkImportedShells =
        system: { nixpkgs
                , pkgs ? (import nixpkgs {
                    inherit system;
                    config.overlays = [ inputs.self.overlays.default ];
                  })
                , ...
                }@inputs: dir:
        importNixWrapFlattenAttrs
          (module:
          pkgs.callPackage
            module.__import.value
            inputs)
          dir;

      imported = mkImportedShells system inputs dir;
    in
    imported;

  mkChecks = { system, inputs, dir }:
    let
      mkImportedChecks = system: { nixpkgs
                                 , pkgs ? (import nixpkgs {
                                     inherit system;
                                     config.overlays = [ inputs.self.overlays.default ];
                                   })
                                 , deploy-rs ? null
                                 , ...
                                 }@inputs: dir:
        (importNixWrapFlattenAttrs
          (module:
            pkgs.callPackage
              module.__import.value
              inputs)
          dir) // (
          if deploy-rs == null then { } else
          deploy-rs.lib.${system}.deployChecks inputs.self.deploy
        );
    in
    mkImportedChecks system inputs dir;

  mkFormatter = { system, inputs, dir }:
    let
      mkImportedFormatter = system: { nixpkgs
                                    , pkgs ? (import nixpkgs {
                                        inherit system;
                                        config.overlays = [ inputs.self.overlays.default ];
                                      })
                                    , ...
                                    }@inputs: dir:
        pkgs.writeShellApplication {
          name = "formatter";
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
    in
    mkImportedFormatter system inputs dir;

  mkApps = { system, inputs, dir }:
    let
      mkImportedApps = system: { nixpkgs
                               , pkgs ? (import nixpkgs {
                                   inherit system;
                                   config.overlays = [ inputs.self.overlays.default ];
                                 })
                               , ...
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

      imported = mkImportedApps system inputs dir;
    in
    imported;

  mkPackages = { system, inputs, dir }:
    let
      mkImportedPackages = system: { nixpkgs
                                   , pkgs ? (import nixpkgs {
                                       inherit system;
                                       config.overlays = [ inputs.self.overlays.default ];
                                     })
                                   , ...
                                   }@inputs: dir:
        importNixWrapFlattenAttrs
          (module:
            pkgs.callPackage
              module.__import.value
              inputs)
          dir;

      imported = mkImportedPackages system inputs dir;
    in
    imported;

  mkLib = { inputs, dir }:
    let
      mkImportedLib = inputs: dir:
        importNixWrapFlattenAttrs
          (module: module.__import.value inputs)
          dir;
    in
    mkImportedLib inputs dir;

  mkOverlays = { inputs, dir }:
    let
      mkImportedOverlays = inputs: dir:
        importNixWrapFlattenAttrs
          (module: module.__import.value inputs)
          dir;

      mkComposedOverlay = inputs: dir:
        nixpkgs.lib.composeManyExtensions
          (builtins.attrValues
            (mkImportedOverlays inputs dir));
    in
    (mkImportedOverlays inputs dir) // {
      default = mkComposedOverlay inputs dir;
    };

  mkNixosModules = { inputs, dir }:
    mkModules
      false
      inputs
      dir;

  mkHomeManagerModules = { inputs, dir }:
    mkModules
      true
      inputs
      dir;

  mkNixosConfigurations = { inputs, dir }:
    let
      specialArgs = inputs;

      mkShared = host: {
        options = {
          host = inputs.nixpkgs.lib.mkOption {
            type = inputs.nixpkgs.lib.types.str;
            default = host;
            description = "Imported host name.";
          };
        };

        config = {
          nix.settings.experimental-features =
            [ "nix-command" "flakes" ];
        };
      };

      mkHomeManagerModule = module: host: user: {
        imports = [
          (mkShared host)
          (self.lib.module.mkHomeManagerModule module.__import.value)
          inputs.self.homeManagerModules.default
        ];

        options = {
          user = inputs.nixpkgs.lib.mkOption {
            type = inputs.nixpkgs.lib.types.str;
            default = user;
            description = "Imported user name.";
          };
        };

        config = {
          home.username = user;
          home.homeDirectory = "/home/${user}";
        };
      };

      mkNixosModules = module: host: users: [
        (mkShared host)
        (self.lib.module.mkNixosModule module.__import.value)
        inputs.self.nixosModules.default
        {
          networking.hostName = host;
        }
        (if ((builtins.length users) == 0) then { } else {
          users.users =
            builtins.listToAttrs
              (builtins.map
                (user: {
                  name = user;
                  value = {
                    isNormalUser = true;
                    home = "/home/${user}";
                    createHome = true;
                  };
                })
                users);
        })
        (if !(builtins.hasAttr "home-manager" inputs)
          || ((builtins.length users) == 0) then { } else {
          imports = [
            inputs.home-manager.nixosModules.default
          ];
          home-manager.extraSpecialArgs = specialArgs;
          home-manager.users =
            builtins.listToAttrs
              (builtins.map
                (user: {
                  name = user;
                  value = mkHomeManagerModule module host user;
                })
                users);
        })
      ];

      matrix =
        let
          hostModuleSystems =
            nixpkgs.lib.mapAttrsToList
              (name: value: {
                module = value;
                host = name;
                systems =
                  extractAttr
                    value
                    "systems"
                    flake-utils.lib.defaultSystems;
                users =
                  extractAttr
                    value
                    "users"
                    [ ];
              })
              (importNixWrapFlattenAttrs (x: x) dir);
        in
        nixpkgs.lib.flatten
          (builtins.map
            ({ module, host, systems, users }:
              builtins.map
                (system: {
                  inherit module host system users;
                })
                systems)
            hostModuleSystems);
    in
    builtins.listToAttrs
      (builtins.map
        ({ module, host, system, users }: {
          name = "${host}-${system}";
          value = inputs.nixpkgs.lib.nixosSystem {
            inherit system specialArgs;
            modules = mkNixosModules module host users;
          };
        })
        matrix);

  mkDeployNodes = { inputs }:
    let
      mkImportedDeployNodes =
        { nixpkgs
        , pkgs ? null
        , deploy-rs
        , ...
        }@inputs:
        builtins.mapAttrs
          (name: value:
          let
            nonNullPkgs = if pkgs != null then pkgs else
            (import nixpkgs {
              system = value.pkgs.system;
              config.overlays = [ inputs.self.overlays.default ];
            });
            deployPkgs = import nixpkgs {
              system = value.pkgs.system;
              overlays = [
                deploy-rs.overlay
                (self: super: {
                  deploy-rs = {
                    inherit (nonNullPkgs) deploy-rs;
                    lib = super.deploy-rs.lib;
                  };
                })
              ];
            };

            hostname =
              extractAttr
                value
                "hostname"
                (builtins.abort "hostname required");
            users =
              extractAttr
                value
                "users"
                (builtins.abort "at least one user required");
          in
          {
            inherit hostname;
            sshUser = builtins.head users;
            user = "root";
            profile.system.path =
              deployPkgs.deploy-rs.lib.activate.nixos
                self.nixosConfigurations.${name};
          })
          inputs.self.nixosConfigurations;

      imported = mkImportedDeployNodes inputs;
    in
    imported;


  mkFlake = { inputs, dir }:
    let
      finalDir = builtins.unsafeDiscardStringContext dir;

      systemfulPart = flake-utils.lib.eachDefaultSystem
        (system:
          let
            shellsDir = "${finalDir}/shells";
            formattersDir = "${finalDir}/formatters";
            checksDir = "${finalDir}/checks";
            packagesDir = "${finalDir}/packages";
            appsDir = "${finalDir}/apps";
          in
          (if !(builtins.pathExists shellsDir) then { } else {
            devShells = self.lib.flake.mkShells {
              inherit inputs system;
              dir = shellsDir;
            };
          }) //
          (if !(builtins.pathExists formattersDir) then { } else {
            formatter =
              self.lib.flake.mkFormatter
                {
                  inherit inputs system;
                  dir = formattersDir;
                };
          }) //
          (if !(builtins.pathExists checksDir) then { } else {
            checks =
              self.lib.flake.mkChecks
                {
                  inherit inputs system;
                  dir = checksDir;
                };
          }) //
          (if !(builtins.pathExists packagesDir) then { } else {
            packages =
              self.lib.flake.mkPackages
                {
                  inherit inputs system;
                  dir = packagesDir;
                };
          }) //
          (if !(builtins.pathExists appsDir) then { } else {
            apps =
              self.lib.flake.mkApps
                {
                  inherit inputs system;
                  dir = appsDir;
                };
          }));
      systemlessPart =
        let
          libDir = "${finalDir}/lib";
          overlaysDir = "${finalDir}/overlays";
          modulesDir = "${finalDir}/modules";
          configurationsDir = "${finalDir}/configurations";
        in
        (if !(builtins.pathExists overlaysDir) then { } else {
          overlays = self.lib.flake.mkOverlays {
            inherit inputs;
            dir = overlaysDir;
          };
        }) //
        (if !(builtins.pathExists modulesDir) then { } else {
          nixosModules = self.lib.flake.mkNixosModules {
            inherit inputs;
            dir = modulesDir;
          };
        }) // (if !((builtins.pathExists modulesDir)
        && (builtins.hasAttr "home-manager" inputs)) then { } else {
          homeManagerModules = self.lib.flake.mkHomeManagerModules {
            inherit inputs;
            dir = modulesDir;
          };
        }) // (if !(builtins.pathExists configurationsDir) then { } else {
          nixosConfigurations = self.lib.flake.mkNixosConfigurations {
            inherit inputs;
            dir = configurationsDir;
          };
        }) // (if !(builtins.hasAttr "deploy-rs" inputs) then { } else {
          deploy.nodes = self.lib.flake.mkDeployNodes {
            inherit inputs;
          };
        }) // (if !(builtins.pathExists libDir) then { } else {
          lib = self.lib.flake.mkLib {
            inherit inputs;
            dir = libDir;
          };
        });
    in
    systemfulPart // systemlessPart;
}
