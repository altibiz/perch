{ lib, ... }:

let
  initial = importDirToAttrsWithWrap: prefix: wrap: dir:
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
              else
                importDirToAttrsWithWrap
                  importDirToAttrsWithWrap
                  prefixedName
                  wrap "${dir}/${name}";
        })
      (builtins.readDir dir);

  importDirToAttrsWithWrap = initial initial "";

  importDirToListWithWrap = wrap: dir:
    builtins.map
      (module: module.__import.value)
      (builtins.filter
        (module: module.__import.type == "regular"
          || module.__import.type == "default")
        (lib.collect
          (builtins.hasAttr "__import")
          (initial initial "" wrap dir)));
in
{
  lib.import = {
    dirToAttrsWithWrap =
      importDirToAttrsWithWrap;

    dirToAttrsWithMetadata =
      importDirToAttrsWithWrap
        (imported: imported);

    dirToAttrs =
      importDirToAttrsWithWrap
        (imported: imported.__import.value);

    dirToListWithWrap =
      importDirToListWithWrap;

    dirToListWithMetadata =
      importDirToListWithWrap
        (imported: imported);

    dirToList =
      importDirToListWithWrap
        (imported: imported.__import.value);
  };
}
