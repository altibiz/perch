{ lib, pkgs, ... }:

{
  seal.defaults.devShell = "dev/dev";

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
      nixVersions.stable

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
      coreutils
    ] ++ (lib.optionals pkgs.hostPlatform.is64bit [
      # marksman
      marksman
    ]);
  };
}
