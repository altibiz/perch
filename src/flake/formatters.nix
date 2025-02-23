{ self
, lib
, nixpkgs
, specialArgs
, perchModules
, options
, config
, ...
}:

{
  options.integrate.formatter =
    self.lib.option.mkIntegrationOption
      config
      "formatter";

  options.propagate.formatter = lib.mkOption {
    type =
      lib.types.attrsOf
        lib.types.package;
    default = { };
    description = lib.literalMD ''
      Propagated `formatters` flake output.
    '';
  };

  config.propagate.formatter =
    let
      artifacts =
        self.lib.module.artifacts
          specialArgs
          perchModules
          options
          config
          "formatter"
          perchModules.current;
    in
    builtins.mapAttrs
      (system: formatters:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in
        pkgs.writeShellApplication {
          name = "formatter";
          runtimeInputs = [ ];
          text =
            builtins.concatStringsSep
              "\n"
              (builtins.map
                lib.getExe
                (builtins.attrValues
                  formatters));
        })
      artifacts;
}
