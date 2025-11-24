{ self, lib, ... }:

let
  filter = self.lib3.eval.filter;

  modules = {
    foo = { lib, ... }: {
      options.fooOpt = lib.mkOption {
        type = lib.types.str;
        default = "hi";
      };
    };

    bar = { ... }: {
      config.barVal = 123;
    };

    baz = { ... }: { };
  };

  filterModule =
    originalOptionsLists: originalConfigLists:
    let
      optionsNonEmpty =
        builtins.any (x: x != { }) originalOptionsLists;
      configNonEmpty =
        builtins.any (x: x != { }) originalConfigLists;
    in
    optionsNonEmpty || configNonEmpty;

  specialArgs = { inherit lib; };

  result = filter specialArgs filterModule modules;
in
{
  eval_filter_keeps_only_nonempty =
    (result ? foo) && (result ? bar) && !(result ? baz);

  eval_filter_runs_foo =
    let evalFoo = (result.foo { inherit lib; }); in
    evalFoo ? options && evalFoo.options ? fooOpt;

  eval_filter_runs_bar =
    let evalBar = (result.bar { }); in
    evalBar ? config && evalBar.config ? barVal;
}
