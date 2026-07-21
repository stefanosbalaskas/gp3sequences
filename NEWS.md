# gp3sequences 0.1.0

* Initial public release.
* Created the independent `gp3sequences` package scaffold.
* Added MIT licensing and package-level documentation.
* Added the initial testthat edition 3 infrastructure.
* Defined the initial neutral scope and interpretation boundary.
* Added the initial README and pkgdown website configuration.
* Added a multi-platform GitHub Actions R CMD check workflow for macOS, Windows, Ubuntu release, and Ubuntu devel.
* Added a GitHub Actions pkgdown workflow for automated website building and deployment.
* Added `audit_sequence_data()` and `validate_sequence_data()` for structured input diagnostics.
* Added `prepare_sequence_data()` with explicit missing-state, duplicate-position, repeated-state, duration, and unknown-state policies.
* Added `encode_sequence_data()` for deterministic state dictionaries and transparent state codes.
* Added `summarise_sequence_states()`, `summarise_sequence_transitions()`, and `format_sequence_paths()` for structural sequence summaries.
* Added `extract_sequence_ngrams()` for deterministic contiguous motif enumeration with explicit overlap handling.
* Added `summarise_sequence_motifs()`, `filter_sequence_motifs()`, and `format_sequence_motifs()` for transparent motif prevalence, filtering, and reporting.
* Added `summarise_sequence_motif_positions()` and `format_sequence_motif_positions()` for deterministic structural location summaries.
* Added dependency-free `plot_sequence_motifs()` and `plot_sequence_motif_positions()` visualisations plus a synthetic contiguous-motif workflow article.
