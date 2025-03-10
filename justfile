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
    nix flake check --all-systems
    @just test-all

upgrade:
    nix flake update

test-all *args:
    #!/usr/bin/env bash
    cd "{{ root }}"
    for dir in test/*; do
      if [ -d "$dir" ] && [ -f "$dir/flake.nix" ]; then
        nix flake check \
          --override-flake "perch" "{{ root }}" \
          --all-systems \
          --no-write-lock-file \
          {{ args }} \
          "path:$(realpath "$dir")"
      fi
    done

test test *args:
    nix flake check \
      --override-flake "perch" "{{ root }}" \
      --all-systems \
      --no-write-lock-file \
      {{ args }} \
      $"path:(realpath "{{ root }}/test/{{ test }}")"

repl test *args:
    cd '{{ root }}/test/{{ test }}'; \
      nix repl \
        {{ args }} \
        --override-flake perch '{{ root }}' \
        --expr 'rec { \
          perch = "{{ root }}"; \
          perchFlake = builtins.getFlake perch; \
          test = "{{ root }}/test/{{ test }}"; \
          testFlake = builtins.getFlake test; \
        }'

docs:
    rm -rf '{{ artifacts }}'
    cd '{{ docs }}'; mdbook build
    mv '{{ docs }}/book' '{{ artifacts }}'
