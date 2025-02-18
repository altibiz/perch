{ lib, pkgs, config, ... }:

{
  # TODO: some nicer way do do this
  flake.devShells.default = config.flake.devShells."dev.dev";

  integrate.devShell.devShell = pkgs.mkShell {
    packages = with pkgs; [
      # version control
      git

      # scripts
      nushell
      just

      # nix
      nil
      nixpkgs-fmt

      # markdown
      markdownlint-cli
      nodePackages.markdown-link-check

      # documentation
      simple-http-server
      mdbook

      # spelling
      nodePackages.cspell

      # misc
      nodePackages.prettier
      nodePackages.yaml-language-server
      taplo

      # tools
      fd
    ] ++ (lib.optionals pkgs.hostPlatform.is64bit [
      # marksman
      marksman
    ]);
  };

  integrate.check.check = pkgs.writeShellApplication {
    name = "check";
    runtimeInputs = with pkgs; [
      git
      just
      nodePackages.cspell
      nixpkgs-fmt
      nodePackages.prettier
      markdownlint-cli
      nodePackages.markdown-link-check
      fd
    ];
    text = ''
      root="$(git rev-parse --show-toplevel)"
      cd "$root"
      just --unstable --fmt --check
      cspell lint "$root" --no-progress
      nixpkgs-fmt --check "$root"
      prettier --check "$root"
      markdownlint "$root"
      fd '.*.md' -x \
        markdown-link-check \
          --config .markdown-link-check.json \
          --quiet
      cd "$root"
    '';
  };

  integrate.formatter.formatter = pkgs.writeShellApplication {
    name = "formatter";
    runtimeInputs = with pkgs; [
      git
      just
      nixpkgs-fmt
      nodePackages.prettier
    ];
    text = ''
      root="$(git rev-parse --show-toplevel)"
      cd "$root"
      just --unstable --fmt
      nixpkgs-fmt "$root"
      prettier --write "$root"
    '';
  };
}
