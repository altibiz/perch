{ pkgs, ... }:

pkgs.mkShell {
  packages = with pkgs; [
    # scripts
    nushell
    just

    # nix
    nixpkgs-fmt

    # spelling
    nodePackages.cspell

    # misc
    nodePackages.prettier

    # markdown
    markdownlint-cli
    nodePackages.markdown-link-check

    # tools
    fd
  ];
}
