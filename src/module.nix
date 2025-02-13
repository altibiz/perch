{ ... }:

let
  mkDotObject = specialArgs: perchModule:
    if builtins.isFunction perchModule
    then (perchModule specialArgs)
    else perchModule;

  mkImports = mkModule: specialArgs: perchObject: builtins.map
    (maybeImport:
      if (builtins.isPath maybeImport) || (builtins.isString maybeImport)
      then
        let
          module = (mkModule (import maybeImport) specialArgs);
        in
        if builtins.isAttrs module
        then module // { _file = maybeImport; }
        else module
      else mkModule maybeImport specialArgs)
    (if builtins.hasAttr "imports" perchObject
    then perchObject.imports
    else [ ]);

  mkOptions = specialArgs: perchObject:
    if builtins.hasAttr "disabled" perchObject
    then { }
    else if builtins.hasAttr "options" perchObject
    then perchObject.options
    else { };

  mkConfig = { lib, ... }: path: perchObject:
    if builtins.hasAttr "disabled" perchObject
    then { }
    else if builtins.hasAttr "config" perchObject
    then
      let
        configObject = perchObject.config;
      in
      if lib.hasAttrByPath path configObject
      then lib.getAttrFromPath path configObject
      else { }
    else
      if lib.hasAttrByPath path perchObject
      then lib.getAttrFromPath path perchObject
      else { };

  # NOTE: if pkgs here not demanded other modules don't get access...
  mkNixosModule = mkNixosModule: perchModule: { pkgs, ... } @specialArgs:
    let
      perchObject = mkDotObject specialArgs perchModule;
      imports = mkImports mkNixosModule specialArgs perchObject;
      options = mkOptions specialArgs perchObject;
      config = mkConfig specialArgs [ "system" ] perchObject;
      sharedConfig = mkConfig specialArgs [ "shared" ] perchObject;
    in
    {
      imports = imports ++ [ sharedConfig ];
      inherit options config;
    };

  # NOTE: if pkgs here not demanded other modules don't get access...
  mkHomeManagerModule = mkHomeManagerModule: perchModule: { pkgs, ... } @specialArgs:
    let
      perchObject = mkDotObject specialArgs perchModule;
      imports = mkImports mkHomeManagerModule specialArgs perchObject;
      options = mkOptions specialArgs perchObject;
      config = mkConfig specialArgs [ "home" ] perchObject;
      sharedConfig = mkConfig specialArgs [ "shared" ] perchObject;
    in
    {
      imports = imports ++ [ sharedConfig ];
      inherit options config;
    };
in
{
  mkNixosModule = mkNixosModule mkNixosModule;
  mkHomeManagerModule = mkHomeManagerModule mkHomeManagerModule;
}
