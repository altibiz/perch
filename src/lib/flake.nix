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
  mkShells = { system, inputs, dir, default ? "default" }:
    let
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

      imported = mkImportedShells system inputs dir;
    in
    imported // { default = imported.${default}; };

  mkChecks = { system, inputs, dir }:
    let
      mkImportedChecks = system: { nixpkgs
                                 , pkgs ? (import nixpkgs { inherit system; })
                                 }@inputs: dir:
        importNixWrapFlattenAttrs
          (module:
            pkgs.callPackage
              module.__import.value
              inputs)
          dir;
    in
    mkImportedChecks system inputs dir;

  mkFormatter = { system, inputs, dir }:
    let
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
    in
    mkImportedFormatter system inputs dir;

  mkApps = { system, inputs, dir, default ? "default" }:
    let
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

      imported = mkImportedApps system inputs dir;
    in
    imported // { default = imported.${default}; };

  mkPackages = { system, inputs, dir, default ? "default" }:
    let
      mkImportedPackages = system: { nixpkgs
                                   , pkgs ? (import nixpkgs { inherit system; })
                                   }@inputs: dir:
        importNixWrapFlattenAttrs
          (module:
            pkgs.callPackage
              module.__import.value
              inputs)
          dir;

      imported = mkImportedPackages system inputs dir;
    in
    imported // { default = imported.${default}; };

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

  mkNixosConfigurations = { inputs, dir, users ? [ ] }:
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
      };

      mkHomeManagerModule = module: host: user: {
        options = {
          user = inputs.nixpkgs.lib.mkOption {
            type = inputs.nixpkgs.lib.types.str;
            default = user;
            description = "Imported user name.";
          };
        };

        imports = [
          (mkShared host)
          (self.lib.module.mkHomeManagerModule module.__import.value)
          inputs.self.lib.homeManagerModules.default
        ];
      };

      mkNixosModules = module: host: [
        (mkShared host)
        (self.lib.module.mkNixosModule module.__import.value)
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

      matrix = nixpkgs.lib.cartesianProduct {
        system = flake-utils.lib.defaultSystems;
        hostModule =
          nixpkgs.lib.mapAttrsToList
            (name: value: { host = name; module = value; })
            (importNixWrapFlattenAttrs dir);
      };

      mkImportedNixosConfigurations = inputs: users: dir:
        builtins.listToAttrs
          (builtins.filter
            (configuration: configuration != null)
            (builtins.map
              ({ system, hostModule }:
                let
                  host = hostModule.host;
                  module = hostModule.module;
                in
                if module.__import.type != "regular"
                  && module.__import.type != "default"
                then null
                else
                  {
                    name = "${host}-${system}";
                    value = inputs.nixpkgs.lib.nixosSystem {
                      inherit system specialArgs;
                      modules = mkNixosModules module host;
                    };
                  })
              matrix));
    in
    mkImportedNixosConfigurations
      inputs
      dir
      users;

  mkFlake = { inputs, dir, users ? [ ] }:
    let
      systemfulPart = flake-utils.lib.eachDefaultSystem (system:
        let
          shellsDir = "${dir}/shells";
          formattersDir = "${dir}/formatters";
          checksDir = "${dir}/checks";
          packagesDir = "${dir}/packages";
        in
        {
          devShells = self.lib.flake.mkShells {
            inherit inputs system;
            dir = shellsDir;
          };
          formatter = self.lib.flake.mkFormatter {
            inherit inputs system;
            dir = formattersDir;
          };
          checks = self.lib.flake.mkChecks {
            inherit inputs system;
            dir = checksDir;
          };
          packages = self.lib.flake.mkPackages {
            inherit inputs system;
            dir = packagesDir;
          };
          apps = self.lib.flake.mkApps {
            inherit inputs system;
            dir = packagesDir;
          };
        });
      systemlessPart =
        let
          libDir = "${dir}/lib";
          overlaysDir = "${dir}/overlays";
          modulesDir = "${dir}/modules";
          configurationsDir = "${dir}/configurations";
        in
        {
          lib = self.lib.flake.mkLib {
            inherit inputs;
            dir = libDir;
          };
          overlays = self.lib.flake.mkOverlays {
            inherit inputs;
            dir = overlaysDir;
          };
          nixosModules = self.lib.flake.mkNixosModules {
            inherit inputs;
            dir = modulesDir;
          };
          homeManagerModules = self.lib.flake.mkHomeManagerModules {
            inherit inputs;
            dir = modulesDir;
          };
          nixosConfigurations = self.lib.flake.mkNixosConfigurations {
            inherit inputs;
            dir = configurationsDir;
          };
        };
    in
    systemfulPart // systemlessPart;
}
