# Module

The `module` module contains functions that split a `perchModule` into a
`nixosModule` and `homeManagerModule`.

For example,

```nix
{ pkgs, lib, config, ... }:

let
  cfg = config.perch.hello;
in
{
  options = {
    perch.hello.enable = lib.mkEnableOption "hello";
  };

  config = {
    system = {
      environment.systemPackages = lib.mkIf cfg.enable [
        pkgs.hello
      ];
    };

    home = {
      home.packages = cfg.enable [
        pkgs.hello
      ];
    };
  };
}
```

the module above will be split into a `nixosModule` via
`perch.lib.module.mkNixosModule <module>` like this

```nix

{ pkgs, lib, config, ... }:

let
  cfg = config.perch.hello;
in
{
  options = {
    perch.hello.enable = lib.mkEnableOption "hello";
  };

  config = {
    environment.systemPackages = lib.mkIf cfg.enable [
      pkgs.hello
    ];
  };
}
```

and a `homeManagerModule` via `perch.lib.module.mkHomeManagerModule <module>`
like this:

```nix
{ pkgs, lib, config, ... }:

let
  cfg = config.perch.hello;
in
{
  options = {
    perch.hello.enable = lib.mkEnableOption "hello";
  };

  config = {
    home.packages = cfg.enable [
      pkgs.hello
    ];
  };
}
```

. the `options` and `config` attribute can be omitted just like in
`nixosModules` and `homeManagerModules` to only set `config`. The module can be
an `attrset` or a `thunk`.

Additionally, an attribute called `disabled` can be set to `true` to disable the
entire module.
