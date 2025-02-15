set windows-shell := ["nu.exe", "-c"]
set shell := ["nu", "-c"]

root := absolute_path('')
artifacts := absolute_path('artifacts')
docs := absolute_path('docs')

default:
    @just --choose

format:
    cd '{{ root }}'; just --unstable --fmt
    prettier --write '{{ root }}'
    nixpkgs-fmt '{{ root }}'

lint:
    cd '{{ root }}'; just --unstable --fmt --check
    prettier --check '{{ root }}'
    cspell lint '{{ root }}' --no-progress
    nixpkgs-fmt --check '{{ root }}'
    markdownlint '{{ root }}'
    markdown-link-check \
      --config .markdown-link-check.json \
      --quiet \
      ...(fd '.*.md' | lines)

upgrade:
    nix flake update

test:
    nix run $".#checks.(nix eval --raw --impure --expr "builtins.currentSystem").test"

docs:
    rm -rf '{{ artifacts }}'
    cd '{{ docs }}'; mdbook build
    mv '{{ docs }}/book' '{{ artifacts }}'
