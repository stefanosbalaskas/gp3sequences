# Changelog

## gp3sequences 0.1.0.9000

- Added the complete advanced sequence-analysis roadmap.

- Added deterministic aligned-position consensus sequences and agreement
  summaries.

- Added descriptive between-group state, transition, and length
  comparisons.

- Added Levenshtein, LCS, optimal-matching, and transition-profile
  distances.

- Added hierarchical, PAM, and CLARA clustering interfaces, validation
  metrics, representatives, ensembles, and stability resampling.

- Added transition networks, centrality, communities, higher-order
  transition models, prediction, and sequence-level bootstrap intervals.

- Added dependency-light categorical HMM and mixture-HMM estimation,
  decoding, summaries, and model-comparison tables.

- Added optional adapters for TraMineR, arulesSequences, GrpString,
  seqHMM, igraph, and common gp3tools-style data frames.

- Added four synthetic workflow articles, deterministic tests, and an
  end-to-end smoke test.

- Initial public release.

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
  [`audit_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/audit_sequence_data.md)
  and
  [`validate_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/validate_sequence_data.md)
  for structured input diagnostics.

- Added
  [`prepare_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/prepare_sequence_data.md)
  with explicit missing-state, duplicate-position, repeated-state,
  duration, and unknown-state policies.

- Added
  [`encode_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/encode_sequence_data.md)
  for deterministic state dictionaries and transparent state codes.

- Added
  [`summarise_sequence_states()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/summarise_sequence_states.md),
  [`summarise_sequence_transitions()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/summarise_sequence_transitions.md),
  and
  [`format_sequence_paths()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/format_sequence_paths.md)
  for structural sequence summaries.

- Added
  [`extract_sequence_ngrams()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/extract_sequence_ngrams.md)
  for deterministic contiguous motif enumeration with explicit overlap
  handling.

- Added
  [`summarise_sequence_motifs()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/summarise_sequence_motifs.md),
  [`filter_sequence_motifs()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/filter_sequence_motifs.md),
  and
  [`format_sequence_motifs()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/format_sequence_motifs.md)
  for transparent motif prevalence, filtering, and reporting.

- Added
  [`summarise_sequence_motif_positions()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/summarise_sequence_motif_positions.md)
  and
  [`format_sequence_motif_positions()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/format_sequence_motif_positions.md)
  for deterministic structural location summaries.

- Added dependency-free
  [`plot_sequence_motifs()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/plot_sequence_motifs.md)
  and
  [`plot_sequence_motif_positions()`](https://stefanosbalaskas.github.io/gp3sequences/dev/reference/plot_sequence_motif_positions.md)
  visualisations plus a synthetic contiguous-motif workflow article.
