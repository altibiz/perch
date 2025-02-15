{ lib, ... }:

let
  initial = importDirWrap: prefix: wrap: dir:
    lib.attrsets.mapAttrs'
      (name: type:
        let
          basename = builtins.replaceStrings [ ".nix" ] [ "" ] name;
          prefixedName = if prefix == "" then basename else "${prefix}.${basename}";
        in
        {
          name = if type == "regular" then basename else name;
          value =
            if type == "regular"
            then
              if lib.hasSuffix ".nix" name
              then
                wrap
                  {
                    __import = {
                      path = "${dir}/${name}";
                      name = prefixedName;
                      type = "regular";
                      value = import "${dir}/${name}";
                    };
                  }
              else
                wrap {
                  __import = {
                    path = "${dir}/${name}";
                    name = prefixedName;
                    type = "unknown";
                    value = null;
                  };
                }
            else
              if builtins.pathExists "${dir}/${name}/default.nix"
              then
                wrap
                  {
                    __import = {
                      path = "${dir}/${name}/default.nix";
                      name = prefixedName;
                      type = "default";
                      value = import "${dir}/${name}/default.nix";
                    };
                  }
              else importDirWrap importDirWrap prefixedName wrap "${dir}/${name}";
        })
      (builtins.readDir dir);

  importDirWrap = initial initial "";
in
{
  lib.imports = {
    wrap = importDirWrap;
    meta = importDirWrap (imported: imported);
    dir = importDirWrap (imported: imported.__import.value);
    collect = dir:
      builtins.map
        (module: module.__import.value)
        (builtins.filter
          (module: module.__import.type == "regular"
            || module.__import.type == "default")
          (lib.collect
            (builtins.hasAttr "__import")
            (importDirWrap (imported: imported) dir)));
  };
}
