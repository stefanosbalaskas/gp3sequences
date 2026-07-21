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
- Added
  [`encode_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/reference/encode_sequence_data.md)
  for deterministic state dictionaries and transparent state codes.
- Added
  [`summarise_sequence_states()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_sequence_states.md),
  [`summarise_sequence_transitions()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_sequence_transitions.md),
  and
  [`format_sequence_paths()`](https://stefanosbalaskas.github.io/gp3sequences/reference/format_sequence_paths.md)
  for structural sequence summaries.
- Added
  [`extract_sequence_ngrams()`](https://stefanosbalaskas.github.io/gp3sequences/reference/extract_sequence_ngrams.md)
  for deterministic contiguous motif enumeration with explicit overlap
  handling.
- Added
  [`summarise_sequence_motifs()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_sequence_motifs.md),
  [`filter_sequence_motifs()`](https://stefanosbalaskas.github.io/gp3sequences/reference/filter_sequence_motifs.md),
  and
  [`format_sequence_motifs()`](https://stefanosbalaskas.github.io/gp3sequences/reference/format_sequence_motifs.md)
  for transparent motif prevalence, filtering, and reporting.
- Added
  [`summarise_sequence_motif_positions()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_sequence_motif_positions.md)
  and
  [`format_sequence_motif_positions()`](https://stefanosbalaskas.github.io/gp3sequences/reference/format_sequence_motif_positions.md)
  for deterministic structural location summaries.
- Added dependency-free
  [`plot_sequence_motifs()`](https://stefanosbalaskas.github.io/gp3sequences/reference/plot_sequence_motifs.md)
  and
  [`plot_sequence_motif_positions()`](https://stefanosbalaskas.github.io/gp3sequences/reference/plot_sequence_motif_positions.md)
  visualisations plus a synthetic contiguous-motif workflow article.
