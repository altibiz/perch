{ self, lib, ... }:

let
  specialArgs = { inherit lib; };
in
(
  let
    filter = self.lib3.eval.filter;

    modules = {
      foo = { lib, ... }: {
        _file = ./eval.nix;
        key = "foo";

        options.fooOpt = lib.mkOption {
          type = lib.types.str;
          default = "hi";
        };
      };

      bar = { ... }: {
        _file = ./eval.nix;
        key = "bar";

        config.barVal = 123;
      };

      baz = { ... }: {
        _file = ./eval.nix;
        key = "baz";
      };
    };

    filterModule =
      originalOptionsLists: originalConfigLists:
      let
        optionsNonEmpty = builtins.any
          (module:
            (builtins.removeAttrs module [ "_file" "key" ])
            != { })
          originalOptionsLists;
        configNonEmpty =
          builtins.any
            (module:
              (builtins.removeAttrs module [ "_file" "key" ])
              != { })
            originalConfigLists;
      in
      optionsNonEmpty || configNonEmpty;

    filterResult = filter specialArgs filterModule modules;

  in
  {
    eval_filter_keeps_only_nonempty =
      (filterResult ? foo) && (filterResult ? bar) && !(filterResult ? baz);

    eval_filter_runs_foo =
      let evalFoo = (filterResult.foo { inherit lib; }); in
      evalFoo ? options && evalFoo.options ? fooOpt;

    eval_filter_runs_bar =
      let evalBar = (filterResult.bar { }); in
      evalBar ? config && evalBar.config ? barVal;
  }
) // (
  let
    flake = self.lib3.eval.flake;

    inputModules = {
      alpha = {
        mod = { lib, pkgs, ... }: {
          _file = ./eval.nix;
          key = "input-alpha-mod";

          options = {
            nixosModule = lib.mkOption {
              type = lib.types.attrsOf lib.types.any;
              default = { };
            };

            publicThing = lib.mkOption {
              type = lib.types.attrsOf lib.types.any;
              default = { };
            };
          };

          config.eval.privateConfig = [ [ "nixosModule" ] ];
          config.eval.publicConfig = [ [ "publicThing" ] ];
          config.eval.allowedArgs = [ "pkgs" ];

          config.nixosModule = {
            name = "alpha-mod";
            wantsPkgs = true;
          };

          config.publicThing = {
            hello = "alpha";
            ref = pkgs;
          };
        };
      };
    };

    selfModules = {
      selfmod = { lib, pkgs, ... }: {
        _file = ./eval.nix;
        key = "self-mod";

        config.nixosModule = {
          name = "self-mod";
          wantsPkgs = true;
        };

        config.publicThing = {
          hello = "self";
          ref = pkgs;
        };
      };
    };

    flakeResult = flake specialArgs inputModules selfModules;
  in
  {
    eval_flake_modules_public_only =
      let mods = flakeResult.config.flake.modules; in
      mods.selfmod ? config
      && mods.selfmod.config ? publicThing
      && !(mods.selfmod.config ? nixosModule)
      && mods.mod ? config
      && mods.mod.config ? publicThing
      && !(mods.mod.config ? nixosModule);

    eval_flake_args_has_self_full_modules =
      let
        argsMods = flakeResult.config._module.args.flakeModules;
        m = builtins.head argsMods;
      in
      argsMods != null
      && builtins.length argsMods == 1
      && m ? options && m ? config
      && m.config ? nixosModule
      && m.config ? publicThing;

    eval_flake_allowedArgs_has_pkgs =
      builtins.elem "pkgs" flakeResult.config.eval.allowedArgs;

    eval_flake_public_values_ok =
      let mods = flakeResult.config.flake.modules; in
      mods.selfmod.config.publicThing.hello == "self"
      && mods.mod.config.publicThing.hello == "alpha";
  }
)
