{ writeShellApplication, nixVersions, coreutils, git, ... }:

writeShellApplication {
  name = "test";
  runtimeInputs = [ git coreutils nixVersions.stable ];
  text = ''
    root="$(git rev-parse --show-toplevel)"
    cd "$root"
    for dir in test/*; do
      if [ -d "$dir" ] && [ -f "$dir/flake.nix" ]; then
        nix flake lock \
          --override-input "perch" "$root" \
          "path:$(realpath "$dir")"
      fi
    done
  '';
}
