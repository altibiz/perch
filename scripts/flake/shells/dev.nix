{ mkShell, pkgs, ... }:

mkShell {
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
    marksman
    taplo

    # tools
    fd
  ];
}
