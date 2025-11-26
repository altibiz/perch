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
      input = {
        module = { specialArgs, flakeModules, lib, allowed, ... }: {
          _file = ./eval.nix;
          key = "input";

          options = {
            private = lib.mkOption {
              type = lib.types.attrsOf lib.types.raw;
              default = { };
            };

            public = lib.mkOption {
              type = lib.types.attrsOf lib.types.raw;
              default = { };
            };
          };

          config.eval.privateConfig = [ [ "private" ] ];
          config.eval.publicConfig = [ [ "public" ] ];
          config.eval.allowedArgs = [ "allowed" ];

          config.private.input = {
            input = "input";
            allowed = allowed;
          };

          config.public.input =
            let
              eval = lib.evalModules {
                specialArgs = specialArgs // { allowed = "inputAllowed"; };
                modules = (builtins.attrValues flakeModules) ++ [{
                  options.public = lib.mkOption {
                    type = lib.types.attrsOf lib.types.raw;
                    default = { };
                  };
                  options.private = lib.mkOption {
                    type = lib.types.attrsOf lib.types.raw;
                    default = { };
                  };
                }];
              };
            in
            if eval.config.private ? self
            then {
              self = eval.config.private.self.allowed;
              input = "input";
              allowed = allowed;
            }
            else {
              input = "input";
              allowed = allowed;
            };
        };
      };
    };

    selfModules = {
      self = { lib, allowed, ... }: {
        _file = ./eval.nix;
        key = "self";

        config.private.self = {
          self = "self";
          allowed = allowed;
        };

        config.public.self = {
          self = "self";
          allowed = allowed;
        };
      };
    };

    flakeResult = flake specialArgs inputModules selfModules;
  in
  {
    eval_flake_config_ok =
      let
        config =
          self.lib3.attrset.removeAttrByPath
            [ "flake" "modules" "self" ]
            flakeResult.config;
      in
      config == {
        eval.privateConfig = [
          [ "private" ]
          [ "flake" "modules" ]
        ];
        eval.publicConfig = [
          [ "public" ]
          [ "eval" "privateConfig" ]
          [ "eval" "publicConfig" ]
          [ "eval" "allowedArgs" ]
        ];
        eval.allowedArgs = [ "allowed" ];

        public.input = {
          self = "inputAllowed";
          input = "input";
          allowed = null;
        };

        private.self = {
          self = "self";
          allowed = null;
        };

        public.self = {
          self = "self";
          allowed = null;
        };

        flake.modules = { };
      };

    eval_exported_flake_public_only =
      let
        eval =
          flake
            (specialArgs // {
              allowed = "eval_exported_flake_public_only";
            })
            (inputModules // { self = flakeResult.config.flake.modules; })
            { };
      in
      eval.config == {
        eval.privateConfig = [
          [ "private" ]
          [ "flake" "modules" ]
        ];
        eval.publicConfig = [
          [ "public" ]
          [ "eval" "privateConfig" ]
          [ "eval" "publicConfig" ]
          [ "eval" "allowedArgs" ]
        ];
        eval.allowedArgs = [ "allowed" ];

        private = { };

        public.input = {
          input = "input";
          allowed = "eval_exported_flake_public_only";
        };

        public.self = {
          self = "self";
          allowed = "eval_exported_flake_public_only";
        };

        flake.modules = { };
      };
  }
)
