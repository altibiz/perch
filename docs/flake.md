# Flake

The `flake` module contains opinionated functions that make it easier to create
flakes from an opinionated directory hierarchy. For now, this directory
hierarchy cannot be customized, but it is possible to add support for further
customization in the future.

From a top-down point of view the `flake` module exports the top-level function
`perch.lib.flake.mkFlake`. This function takes in a directory hierarchy as such:

```txt
| dir
|
|---| shells
|   |   shell1.nix
|   |   shell2.nix
|
|---| formatters
|   |   formatter1.nix
|   |   formatter2.nix
|
|---| checks
|   |   check1.nix
|   |   check2.nix
|
|---| packages
|   |   package1.nix
|   |   package2.nix
|
|---| apps
|   |   app1.nix
|   |   app2.nix
|
|---| lib
|   |   lib1.nix
|   |   lib2.nix
|
|---| overlays
|   |   overlay1.nix
|   |   overlay2.nix
|
|---| modules
|   |   module1.nix
|   |   module2.nix
|
|---| configurations
    |   configuration1.nix
    |   configuration2.nix
```

and turns with the invocation
`perch.lib.flake.mkFlake { inherit inputs; dir = "${inputs.self}/dir"; }` it
into flake outputs as such:

```nix
{ self, nixpkgs, deploy-rs ? null, home-manager ? null, ... }@inputs:

let
  pkgs = import nixpkgs {
    system = <current-system>;
    config.overlays = [ self.overlays.default ];
  };

  deployPkgs = import nixpkgs {
    system = <current-system>;
    overlays = [
      deploy-rs.overlay
      (self: super: {
        deploy-rs = {
          inherit (pkgs) deploy-rs;
          lib = super.deploy-rs.lib;
        };
      })
    ];
  };
in
{
  devShells.<default-systems...>.shell1 =
    pkgs.callPackage
      (import "dir/shells/shell1.nix")
      inputs;
  devShells.<default-systems...>.shell2 =
    pkgs.callPackage
      (import "dir/shells/shell2.nix")
      inputs;

  formatter.<default-systems...> = pkgs.writeShellApplication {
    name = "formatter";
    text = ''
      ${pkgs.lib.getExe
        (pkgs.callPackage
          (import "dir/formatters/formatter1.nix")
          inputs)}
      ${pkgs.lib.getExe
        (pkgs.callPackage
          (import "dir/formatters/formatter2.nix")
          inputs)}
    '';
  };

  checks.<default-systems...>.check1 =
    pkgs.callPackage
      (import "dir/checks/check1.nix")
      inputs;
  checks.<default-systems...>.check2 =
    pkgs.callPackage
      (import "dir/checks/check2.nix")
      inputs;

  packages.<default-systems...>.package1 =
    pkgs.callPackage
      (import "dir/packages/package1.nix")
      inputs;
  packages.<default-systems...>.package2 =
    pkgs.callPackage
      (import "dir/packages/package2.nix")
      inputs;

  apps.<default-systems...>.app1 = {
    type = "app";
    program =
      pkgs.lib.getExe
        (pkgs.callPackage
          (import "dir/apps/app1.nix")
          inputs);
  };
  apps.<default-systems...>.app2 = {
    type = "app";
    program =
      pkgs.lib.getExe
        (pkgs.callPackage
          (import "dir/apps/app2.nix")
          inputs);
  };

  lib.lib1 = (import "dir/lib/lib1.nix") inputs;
  lib.lib2 = (import "dir/lib/lib2.nix") inputs;

  overlays.overlay1 = (import "dir/overlays/overlay1.nix") inputs;
  overlays.overlay2 = (import "dir/overlays/overlay2.nix") inputs;
  overlays.default = nixpkgs.composeManyExtensions [
    self.overlays.overlay1
    self.overlays.overlay2
  ];

  nixosModules.module1 =
    perch.lib.modules.mkNixosModule
      (import "dir/modules/module1.nix");
  nixosModules.module2 =
    perch.lib.modules.mkNixosModule
      (import "dir/modules/module2.nix");
  nixosModules.default = {
    imports = [
      self.nixosModules.module1
      self.nixosModules.module2
    ];
    config = {
      nixpkgs.overlays = [ self.overlays.default ];
      system.environmentPackages = self.packages;
    };
  };

  homeManagerModules.module1 =
    perch.lib.modules.mkHomeManagerModule
      (import "dir/modules/module1.nix");
  homeManagerModules.module2 =
    perch.lib.modules.mkHomeManagerModule
      (import "dir/modules/module2.nix");
  homeManagerModules.default = {
    imports = [
      self.homeManagerModules.module1
      self.homeManagerModules.module2
    ];
    config = {
      nixpkgs.overlays = [ self.overlays.default ];
      home.packages = self.packages;
    };
  };

  nixosConfigurations."configuration1-${<current-system>}" =
    nixpkgs.lib.nixosSystem {
      system = "<current-system>";
      name = "configuration1-${<current-system>}";
      modules = [
        (perch.lib.module.mkNixosModule
          (import "dir/configurations/configuration1.nix"))
        self.nixosModules.default
        {
          networking.hostName = "configuration1";
          users.users.<current-user> = {
            isNormalUser = true;
            home = "/home/${<current-user>}";
            createHome = true;
          };
        }
        {
          imports = [
            inputs.home-manager.nixosModules.default
          ];
          home-manager.extraSpecialArgs = specialArgs;
          home-manager.users.<current-user> = [
            (perch.lib.module.mkHomeManagerModule
              (import "dir/configurations/configuration1.nix"))
            self.homeManagerModules.default
          ];
        }
      ];
    }; Humble Nix framework and Rust CLI for creating multi-node systems.
  nixosConfigurations."configuration2-${<current-system>}" =
    nixpkgs.lib.nixosSystem {
      system = "<current-system>";
      name = "$configuration2-${<current-system>}";
      modules = [
        (perch.lib.module.mkNixosModule
          (import "dir/configurations/configuration2.nix"))
        self.nixosModules.default
        {
          networking.hostName = "configuration2";
          users.users.<current-user> = {
            isNormalUser = true;
            home = "/home/${<current-user>}";
            createHome = true;
          };
        }
        {
          imports = [
            inputs.home-manager.nixosModules.default
          ];
          home-manager.extraSpecialArgs = specialArgs;
          home-manager.users.<current-user> = [
            (perch.lib.module.mkHomeManagerModule
              (import "dir/configurations/configuration2.nix"))
            self.homeManagerModules.default
          ];
        }
      ];
    };

  deploy.nodes."configuration1-${<current-system>}" = {
    hostname = "<hostname>";
    sshUser = "<first-user>";
    user = "root";
    profile.system.path =
      deployPkgs.deploy-rs.lib.activate.nixos
        self.nixosConfigurations."configuration1-${<current-system>}";
  };
  deploy.nodes."configuration2-${<current-system>}" = {
    hostname = "<hostname>";
    sshUser = "<first-user>";
    user = "root";
    profile.system.path =
      deployPkgs.deploy-rs.lib.activate.nixos
        self.nixosConfigurations."configuration2-${<current-system>}";
  };
}
```

. Some details are left out for brevity.

Explanations for pseudocode variables written in angle brackets (`<...>`):

- `<default-systems...>`: This is the result of calling these outputs with
  `flake-utils.lib.eachDefaultSystem`. It is best advised that you read
  [`flake-utils`](https://github.com/numtide/flake-utils) documentation on what
  this does.
- `<current-system>`:
  - For anything other than `nixosConfigurations` and `deploy.nodes` this is the
    current system from `<default-systems...>`
  - For `nixosConfigurations` and `deploy.nodes` this is the current system from
    the top level module `systems` attribute. The top level module (in the
    example above `dir/configurations/configuration1.nix` and
    `dir/configurations/configuration1.nix`) can additionally have a top-level
    attribute called `systems` denoting for which systems the
    `nixosConfiguration` will be built. For function modules this attribute is
    evaluated by setting all `builtins.functionAttrs` to `null` before passing
    them to the function and then getting the `systems` attribute.
- `<current-user>`: This is the current user being evaluated from the list of
  users for a particular configuration. The list of users for a particular
  configuration is denoted via a top-level module attribute called `users`. This
  attribute is evaluated in the same manner as the top-level `systems`
  attribute.
- `<hostname>`: This is a top-level module attribute called `hostname`. This
  attribute is evaluated in the same manner as the top-level `systems`
  attribute. It is required if your flake inputs contain `deploy-rs`.
- `<first-users>`: This is the first user in the top-level attribute `users`. It
  is required if your flake inputs contain `deploy-rs`.

As indicated by the optionality of the `host-manager` and `deploy-rs` arguments,
these integrations are optional. For more information on what these intgrations
do please refer to the
[`home-manager`](https://github.com/nix-community/home-manager) and
[`deploy-rs`](https://github.com/serokell/deploy-rs) documentation pages. In
short, `home-manager` "provides a basic system for managing a user environment"
and `deploy-rs` is "a simple multi-profile Nix-flake deploy tool".

Additionally, the module consists of functions being utilized by the
`perch.lib.flake.mkFlake` function to evaluate all flake output types. These
functions are:

- `mkShells`, `mkChecks`, `mkFormatter`, `mkApps`, `mkPackages`: take an attrset
  of type `{ system, inputs, dir }`where the`dir`attribute
  is`dir/{shells,checks,formatters,apps,packages}`in the example above and
  produces the`{devShells,checks,formatter,apps,packages}` outputs as described
  in the example above.
- `mkLib`, `mkOverlays`, `mkNixosModules`, `mkHomeManagerModules`,
  `mkNixosConfigurations`: take an attrset of type `{ inputs, dir }`where
  the`dir`attribute is`dir/{lib,overlays,modules,modules,modules}`in the example
  above and produces
  the`{lib,overlays,nixosModules,homeManagerModules,nixosConfigurations}`
  outputs as described in the example above.

When passing in the `dir` attribute just make sure to pass it in string form.
For example instead of passing in a path `./flake` pass it in like so
`${self}/flake`. This is to prevent errors relating to [strings with contexts
not being allowed to refer to store paths].

[strings with contexts not being allowed to refer to store paths]:
  https://discourse.nixos.org/t/not-allowed-to-refer-to-a-store-path-error/5226/3
