{ pkgs, ... }:

{
  integrate.devShell.devShell = pkgs.mkShell {
    packages = with pkgs; [
      # version control
      git

      # scripts
      just
      nushell

      # nix
      nixpkgs-fmt
      nixVersions.stable

      # markdown
      markdownlint-cli
      nodePackages.markdown-link-check

      # spelling
      nodePackages.cspell

      # misc
      nodePackages.prettier

      # tools
      fd
      coreutils
    ];
  };
}
