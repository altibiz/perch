{ pkgs, ... }:

{
  integrate.devShell.devShell = pkgs.mkShell {
    packages = with pkgs; [
      git
      just
      nodePackages.cspell
      nixpkgs-fmt
      nodePackages.prettier
      markdownlint-cli
      nodePackages.markdown-link-check
      fd
      coreutils
      nixVersions.stable
    ];
  };
}
