{ lib, ... }:

let
  importDirToAttrsWithMap =
    let
      initial =
        (importDirToAttrsWithMap: prefix: map: dir:
          lib.attrsets.mapAttrs'
            (name: type:
              let
                nameWithoutExtension =
                  builtins.replaceStrings [ ".nix" ] [ "" ] name;
                prefixedName =
                  if prefix == ""
                  then nameWithoutExtension
                  else "${prefix}.${nameWithoutExtension}";
              in
              {
                name =
                  if type == "regular"
                  then nameWithoutExtension
                  else name;
                value =
                  if type == "regular"
                  then
                    if lib.hasSuffix ".nix" name
                    then
                      map
                        {
                          __import = {
                            path = "${dir}/${name}";
                            name = prefixedName;
                            type = "regular";
                            value = import "${dir}/${name}";
                          };
                        }
                    else
                      map {
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
                      map
                        {
                          __import = {
                            path = "${dir}/${name}/default.nix";
                            name = prefixedName;
                            type = "default";
                            value = import "${dir}/${name}/default.nix";
                          };
                        }
                    else
                      importDirToAttrsWithMap
                        importDirToAttrsWithMap
                        prefixedName
                        map "${dir}/${name}";
              })
            (builtins.readDir dir));
    in
    initial initial "";

  importDirToListWithMap = map: dir:
    builtins.map
      (module: map module.__import.value)
      (builtins.filter
        (module: module.__import.type == "regular"
          || module.__import.type == "default")
        (lib.collect
          (builtins.hasAttr "__import")
          (importDirToAttrsWithMap (module: module) dir)));
in
{
  lib.import = {
    dirToAttrsWithMap =
      importDirToAttrsWithMap;

    dirToAttrsWithMetadata =
      importDirToAttrsWithMap
        (imported: imported);

    dirToAttrs =
      importDirToAttrsWithMap
        (imported: imported.__import.value);

    dirToListWithMap =
      importDirToListWithMap;

    dirToListWithMetadata =
      importDirToListWithMap
        (imported: imported);

    dirToList =
      importDirToListWithMap
        (imported: imported.__import.value);
  };
}
