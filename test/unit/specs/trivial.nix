{ self, lib, ... }:

let
  dummyFun =
    { a, b ? 2 }:
    { out = a + b; inherit a b; };

  argsOnly =
    { x, y ? 10 }:
    { sum = x + y; };

  dummyModule =
    { lib, ... }:
    {
      x = 1;
      y = 2;
      computed = lib.add 39 3;
    };

  mkModuleFile = content:
    let f = builtins.toFile "mod.nix" content;
    in f;
in
{
  mapFunctionResult_wraps_result =
    let
      f = dummyFun;
      mapped = self.lib3.module.mapFunctionResult (res: res // { tag = "ok"; }) f;
      r = mapped { a = 3; };
    in
    r == { out = 5; a = 3; b = 2; tag = "ok"; };

  mapFunctionResult_preserves_args =
    let
      f = dummyFun;
      mapped = self.lib3.module.mapFunctionResult (res: res) f;
      args = builtins.attrNames (lib.functionArgs mapped);
    in
    builtins.all (k: builtins.elem k args) [ "a" "b" ];

  mapFunctionArgs_maps_inputs =
    let
      f = argsOnly;
      mapped = self.lib3.module.mapFunctionArgs (args: args // { x = args.x * 2; }) f;
    in
    mapped { x = 5; } == { sum = 5 * 2 + 10; };

  mapFunctionArgs_preserves_args =
    let
      f = argsOnly;
      mapped = self.lib3.module.mapFunctionArgs (x: x) f;
      args = lib.functionArgs mapped;
    in
    (args ? x) && (args ? y);

  importIfPath_path_attrset =
    let
      modFile =
        mkModuleFile ''
          { lib, ... }: { hello = "world"; }
        '';
      imported = self.lib3.module.importIfPath modFile;
      result = imported { inherit lib; };
    in
    (result.hello == "world")
    && (result ? _file)
    && (result ? key)
    && (result._file == modFile)
    && (result.key == modFile);

  importIfPath_path_plain_attrset =
    let
      modFile =
        mkModuleFile ''
          { hello = "attrset"; n = 7; }
        '';
      imported = self.lib3.module.importIfPath modFile;
    in
    imported == { hello = "attrset"; n = 7; _file = modFile; key = modFile; };

  importIfPath_string_path =
    let
      modFile =
        mkModuleFile ''
          { lib, ... }: { a = 1; }
        '';
      imported = self.lib3.module.importIfPath (toString modFile);
      result = imported { inherit lib; };
    in
    (result.a == 1)
    && (result._file == toString modFile)
    && (result.key == toString modFile);

  importIfPath_function_value =
    let
      imported = self.lib3.module.importIfPath dummyModule;
      result = imported { inherit lib; };
    in
    (result == { x = 1; y = 2; computed = 42; });

  importIfPath_plain_attrset_value =
    let
      value = { k = "v"; };
      imported = self.lib3.module.importIfPath value;
    in
    imported == value;

  mapAttrsetImports_maps_each_import =
    let
      modA = mkModuleFile '' { lib, ... }: { name = "A"; } '';
      modB = mkModuleFile '' { lib, ... }: { name = "B"; } '';
      attrset =
        {
          imports = [ modA modB ];
          root = true;
        };
      mapped =
        self.lib3.module.mapAttrsetImports
          (m: self.lib3.module.mapFunctionResult (r: r // { via = "mapped"; }) m)
          attrset;

      allGood =
        builtins.all
          (f:
            let m = f { inherit lib; }; in (m ? _file)
              && (m ? key)
              && (m ? via)
              && (m.via == "mapped"))
          mapped.imports;
    in
    (mapped.root == true)
    && (builtins.length mapped.imports == 2)
    && allGood;

  mapAttrsetImports_noop_when_no_imports =
    let
      attrset = { x = 1; };
      mapped = self.lib3.module.mapAttrsetImports (x: x) attrset;
    in
    mapped == attrset;
}
