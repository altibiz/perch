<!-- markdownlint-disable MD024 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and adheres to [Semantic Versioning](https://semver.org/).

## [2.2.1] - 2025-04-19

### Added

- `module.distill` for filtering out modules during module eval
- `module.patch` for patching modules in various scenarios

### Changed

- use `module.distill` where appropriate for optimization
- `scratch` test modules

## [2.1.1] - 2025-03-02

### Added

- `root` into `specialArgs` when calling `perch.lib.flake.make`

## [2.0.1] - 2025-02-26

### Changed

- fixed `branch` and `integrate` prefix operation ordering

## [2.0.0] - 2025-02-24

### Added

- new module system

### Changed

- import functions

### Removed

- `nixosModule` + `homeManagerModule` combinator

## [1.0.0] - 2025-02-12

### Added

- `nixosModule` + `homeManagerModule` combinator
- import functions

[2.2.1]: https://github.com/altibiz/perch/compare/2.1.1...2.2.1
[2.1.1]: https://github.com/altibiz/perch/compare/2.0.1...2.1.1
[2.0.1]: https://github.com/altibiz/perch/compare/2.0.0...2.0.1
[2.0.0]: https://github.com/altibiz/perch/compare/1.0.0...2.0.0
[1.0.0]: https://github.com/altibiz/perch/releases/tag/1.0.0
