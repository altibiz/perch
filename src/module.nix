{ nixpkgs, ... }:

let
  mkPerchObject = specialArgs: perchModule:
    if builtins.isFunction perchModule
    then (perchModule specialArgs)
    else perchModule;

  mkImports = mkModule: specialArgs: perchObject: builtins.map
    (maybeImport:
      if (builtins.isPath maybeImport) || (builtins.isString maybeImport)
      then
        let
          path = maybeImport;
          module = (mkModule path specialArgs);
        in
        if builtins.isAttrs module
        then module // { _file = path; }
        else module
      else
        let
          imported = maybeImport;
          module = mkModule imported specialArgs;
        in
        mkModule module specialArgs)
    (if builtins.hasAttr "imports" perchObject
    then perchObject.imports
    else [ ]);

  mkOptions = specialArgs: perchObject:
    if builtins.hasAttr "disabled" perchObject
    then { }
    else if builtins.hasAttr "options" perchObject
    then perchObject.options
    else { };

  # TODO: when not containing config, use top level with stripped attrs
  mkConfig = specialArgs: perchObject:
    if builtins.hasAttr "disabled" perchObject
    then { }
    else if builtins.hasAttr "config" perchObject
    then perchObject.config
    else { };

  mkModule = path: perchObject:
    if builtins.hasAttr "disabled" perchObject
    then { }
    else if builtins.hasAttr "modules" perchObject
    then
      let
        moduleObject = perchObject.modules;
      in
      if nixpkgs.lib.hasAttrByPath path moduleObject
      then nixpkgs.lib.getAttrFromPath path moduleObject
      else { }
    else
      if nixpkgs.lib.hasAttrByPath path perchObject
      then nixpkgs.lib.getAttrFromPath path perchObject
      else { };

  # NOTE: if pkgs here not demanded other modules don't get access...
  mkNixosModule = mkNixosModule: maybeImported: { pkgs, ... } @specialArgs:
    let
      perchModule =
        if (builtins.isPath maybeImported)
          || (builtins.isString maybeImported)
        then import maybeImported
        else maybeImported;
      perchObject = mkPerchObject specialArgs perchModule;
      imports = mkImports mkNixosModule specialArgs perchObject;
      options = mkOptions specialArgs perchObject;
      config = mkConfig specialArgs perchObject;
      module = mkModule [ "system" ] perchObject;
    in
    {
      imports = imports ++ [ module ];
      inherit config options;
    } // (if (builtins.isPath maybeImported)
    || (builtins.isString maybeImported) then {
      _file = maybeImported;
    } else { });

  # NOTE: if pkgs here not demanded other modules don't get access...
  mkHomeManagerModule = mkHomeManagerModule: maybeImported: { pkgs, ... } @specialArgs:
    let
      perchModule =
        if (builtins.isPath maybeImported)
          || (builtins.isString maybeImported)
        then import maybeImported
        else maybeImported;
      perchObject = mkPerchObject specialArgs perchModule;
      imports = mkImports mkHomeManagerModule specialArgs perchObject;
      options = mkOptions specialArgs perchObject;
      config = mkConfig specialArgs perchObject;
      module = mkModule [ "home" ] perchObject;
    in
    {
      imports = imports ++ [ module ];
      inherit options config;
    } // (if (builtins.isPath maybeImported)
    || (builtins.isString maybeImported) then {
      _file = maybeImported;
    } else { });
in
{
  mkNixosModule = mkNixosModule mkNixosModule;
  mkHomeManagerModule = mkHomeManagerModule mkHomeManagerModule;
}
