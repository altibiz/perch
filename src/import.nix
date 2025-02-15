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
      map
      (builtins.filter
        (module: module.__import.type == "regular"
          || module.__import.type == "default")
        (lib.collect
          (builtins.hasAttr "__import")
          (importDirToAttrsWithMap (module: module) dir)));

  importDirToFlatAttrsWithMap = map: dir:
    builtins.listToAttrs
      (builtins.map
        (module: {
          name = module.__import.name;
          value = map module;
        })
        (importDirToListWithMap (module: module) dir));
in
{
  flake.lib.import = {
    dirToAttrsWithMap =
      importDirToAttrsWithMap;

    dirToAttrsWithMetadata =
      importDirToAttrsWithMap
        (imported: imported);

    dirToValueAttrs =
      importDirToAttrsWithMap
        (imported: imported.__import.value);

    dirToPathAttrs =
      importDirToAttrsWithMap
        (imported: imported.__import.path);

    dirToListWithMap =
      importDirToListWithMap;

    dirToListWithMetadata =
      importDirToListWithMap
        (imported: imported);

    dirToValueList =
      importDirToListWithMap
        (imported: imported.__import.value);

    dirToPathList =
      importDirToListWithMap
        (imported: imported.__import.path);

    dirToFlatAttrsWithMap =
      importDirToFlatAttrsWithMap;

    dirToFlatAttrsWithMetadata =
      importDirToFlatAttrsWithMap
        (imported: imported);

    dirToFlatValueAttrs =
      importDirToFlatAttrsWithMap
        (imported: imported.__import.value);

    dirToFlatPathAttrs =
      importDirToFlatAttrsWithMap
        (imported: imported.__import.path);
  };
}
