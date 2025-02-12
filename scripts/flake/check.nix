{ nixpkgs, ... }:

{
  mkChecks = system:
    let
      pkgs = import nixpkgs { inherit system; };
    in
    {
      just = pkgs.writeShellApplication {
        name = "just";
        runtimeInputs = [ pkgs.just ];
        text = ''
          cd "$(git rev-parse --show-toplevel)"
          just --unstable --fmt --check
        '';
      };
      prettier = pkgs.writeShellApplication {
        name = "prettier";
        runtimeInputs = [ pkgs.nodePackages.prettier ];
        text = ''
          prettier --check "$(git rev-parse --show-toplevel)"
        '';
      };
      markdownlint = pkgs.writeShellApplication {
        name = "prettier";
        runtimeInputs = [ pkgs.markdownlint-cli ];
        text = ''
          markdownlint "$(git rev-parse --show-toplevel)"
        '';
      };
      markdown-link-check = pkgs.writeShellApplication {
        name = "prettier";
        runtimeInputs = [
          pkgs.nodePackages.markdown-link-check
          pkgs.fd
        ];
        text = ''
          cd "$(git rev-parse --show-toplevel)"
          fd '.*.md' -x \
            markdown-link-check \
              --config .markdown-link-check.json \
              --quiet
        '';
      };
      nixpkgs-fmt = pkgs.writeShellApplication {
        name = "nixpkgs-fmt";
        runtimeInputs = [ pkgs.nixpkgs-fmt ];
        text = ''
          nixpkgs-fmt --check "$(git rev-parse --show-toplevel)"
        '';
      };
      cspell = pkgs.writeShellApplication {
        name = "cspell";
        runtimeInputs = [ pkgs.nodePackages.cspell ];
        text = ''
          cspell lint "$(git rev-parse --show-toplevel)" --no-progress
        '';
      };
    };
}
