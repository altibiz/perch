{ writeShellApplication, nixVersions, coreutils, git, ... }:

writeShellApplication {
  name = "test";
  runtimeInputs = [ git coreutils nixVersions.stable ];
  text = ''
    cd "$(git rev-parse --show-toplevel)"
    for dir in test/*; do
      if [ -d "$dir" ] && [ -f "$dir/flake.nix" ]; then
        nix flake lock \
          --all-systems \
          --override-input self "path:$(realpath "$dir")"
      fi
    done
  '';
}
