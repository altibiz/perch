{ lib, pkgs, nixt, ... }:

{
  defaultDevShell = true;
  devShell = pkgs.mkShell {
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
      nixt.packages.${pkgs.system}.default

      # markdown
      markdownlint-cli
      nodePackages.markdown-link-check

      # documentation
      simple-http-server
      mdbook

      # spelling
      nodePackages.cspell

      # misc
      vscode-langservers-extracted
      nodePackages.prettier
      nodePackages.yaml-language-server
      taplo
    ] ++ (lib.optionals pkgs.hostPlatform.is64bit [
      marksman
    ]) ++ [

      # tools
      fd
      coreutils
    ];
  };
}
