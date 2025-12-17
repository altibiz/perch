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
    @just test-e2e-all
    @just test-unit

upgrade:
    nix flake update

test-e2e-all *args:
    #!/usr/bin/env nu
    ls "{{ root }}/test/e2e" | get name | each {
      (nix flake check
        --override-flake "perch" "{{ root }}"
        --all-systems
        --no-write-lock-file
        {{ args }}
        $"path:(realpath $in)")
    }

test-e2e test *args:
    nix flake check \
      --override-flake "perch" "{{ root }}" \
      --all-systems \
      --no-write-lock-file \
      {{ args }} \
      $"path:("{{ root }}/test/e2e/{{ test }}")"

test-unit filter="":
    #!/usr/bin/env nu
    let result = (nix eval
      --json
      --impure
      --show-trace
      --expr
      '(builtins.getFlake "{{ root }}/test/unit").test {
        root = "{{ root }}";
        filter = "{{ filter }}";
      }') | complete
    if $result.exit_code != 0 {
      print -e $result.stderr
      exit 1
    }

    let json = $result.stdout | from json
    print $json.summary
    if not $json.ok {
      print -e $result.stderr
      exit 1
    }

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
