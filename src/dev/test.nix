{ pkgs, ... }:

{
  integrate.check.check = pkgs.writeShellApplication {
    name = "check";
    runtimeInputs = with pkgs; [
      git
      coreutils
      nixVersions.stable
    ];
    text = ''
      root="$(git rev-parse --show-toplevel)"
      cd "$root"
      for dir in test/*; do
        if [ -d "$dir" ] && [ -f "$dir/flake.nix" ]; then
          nix flake check \
            --override-input "perch" "$root" \
            --all-systems "path:$(realpath "$dir")"
        fi
      done
    '';
  };
}
