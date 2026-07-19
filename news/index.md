# Changelog

## gp3sequences 0.0.0.9000

- Created the independent `gp3sequences` package scaffold.
- Added MIT licensing and package-level documentation.
- Added the initial testthat edition 3 infrastructure.
- Defined the initial neutral scope and interpretation boundary.
- Added the initial README and pkgdown website configuration.
- Added a multi-platform GitHub Actions R CMD check workflow for macOS,
  Windows, Ubuntu release, and Ubuntu devel.
- Added a GitHub Actions pkgdown workflow for automated website building
  and deployment.
- Added
  [`audit_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/reference/audit_sequence_data.md)
  and
  [`validate_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/reference/validate_sequence_data.md)
  for structured input diagnostics.
- Added
  [`prepare_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/reference/prepare_sequence_data.md)
  with explicit missing-state, duplicate-position, repeated-state,
  duration, and unknown-state policies.
