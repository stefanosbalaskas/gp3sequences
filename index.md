# gp3sequences

**Links:** [CRAN](https://CRAN.R-project.org/package=gp3sequences) ·
[Package website](https://stefanosbalaskas.github.io/gp3sequences/) ·
[Source code](https://github.com/stefanosbalaskas/gp3sequences) · [Issue
tracker](https://github.com/stefanosbalaskas/gp3sequences/issues) ·
[CRAN
checks](https://CRAN.R-project.org/web/checks/check_results_gp3sequences.html)

`gp3sequences` is an independent R package for transparent,
reproducible, and auditable analysis of ordered categorical sequences.
It is designed for ordinary long-format data frames and is not
restricted to Gazepoint exports, eye-tracking data, particular hardware,
or proprietary software.

## Installation

Install the current CRAN release:

``` r

install.packages("gp3sequences")
```

Install the current development version from GitHub:

``` r

pak::pak("stefanosbalaskas/gp3sequences")
```

The CRAN release is version **0.1.0**, published on **30 July 2026**.
The source repository currently develops version **0.2.0.9000**.

## Current development status

The current development version is **0.2.0.9000**, building on the
**0.2.0** release. The package currently exposes **81 public functions**
and the website provides **15 synthetic, reproducible articles**.

The development series combines the audited sequence-data contract with
consensus and group comparisons, sequence distances, clustering and
stability workflows, transition networks, higher-order models,
categorical and mixture hidden Markov models, longitudinal and panel
workflows, bounded non-contiguous subsequences, time-varying models,
multichannel and covariate-dependent HMMs, design-aware inference,
extended visualisations, optional specialist-package adapters, and
analysis-contract/provenance auditing.

## Intended applications

Potential applications include:

- eye-tracking AOI scanpaths;
- website-navigation and customer-journey sequences;
- behavioural-state and task-action sequences;
- interface-interaction sequences;
- educational activity sequences;
- other repeated ordered categorical data.

## Neutral long-format input

The core data contract will require configurable columns corresponding
to `sequence_id`, `sequence_order`, and `state`. Optional participant,
trial, condition, group, timing, duration, weight, and metadata columns
may also be mapped explicitly.

A minimal input may look like this:

``` r

example_sequences <- data.frame(
  sequence_id = rep(c("s1", "s2"), each = 4L),
  sequence_order = rep(1:4, times = 2L),
  state = c(
    "home", "search", "product", "checkout",
    "home", "category", "product", "home"
  ),
  stringsAsFactors = FALSE
)

example_sequences
#>   sequence_id sequence_order    state
#> 1          s1              1     home
#> 2          s1              2   search
#> 3          s1              3  product
#> 4          s1              4 checkout
#> 5          s2              1     home
#> 6          s2              2 category
#> 7          s2              3  product
#> 8          s2              4     home
```

## Current data-contract API

The core sequence-data contract provides three related functions:

- [`audit_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/reference/audit_sequence_data.md)
  reports structured data-quality issues;
- [`validate_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/reference/validate_sequence_data.md)
  returns a compact validity contract;
- [`prepare_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/reference/prepare_sequence_data.md)
  applies explicit preprocessing policies and creates deterministic
  canonical sequence data.

``` r

audit <- audit_sequence_data(
  example_sequences,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state"
)

validation <- validate_sequence_data(
  example_sequences,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state"
)

prepared <- prepare_sequence_data(
  example_sequences,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  repeated_state_policy = "preserve"
)
```

## Analysis contracts and provenance

The 0.2.0.9000 hardening series adds three public functions for
machine-readable capability, contract, provenance, and reproducibility
auditing:

- [`sequence_capabilities()`](https://stefanosbalaskas.github.io/gp3sequences/reference/sequence_capabilities.md)
  inventories native, adapter, reference, handoff, and development
  capabilities without loading optional backend namespaces;
- [`audit_sequence_analysis()`](https://stefanosbalaskas.github.io/gp3sequences/reference/audit_sequence_analysis.md)
  validates supported analysis objects against explicit structural
  contracts and recovers provenance where possible;
- [`compare_sequence_analysis_results()`](https://stefanosbalaskas.github.io/gp3sequences/reference/compare_sequence_analysis_results.md)
  compares contracts, provenance, settings, and optionally result values
  across two analysis objects.

These functions complement the sequence-data contract and provide the
common foundation for the 0.3.0 hardening program.

## Encoding and structural summaries

Related functions support deterministic encoding and descriptive
sequence summaries without assigning substantive meaning to states:

- [`encode_sequence_data()`](https://stefanosbalaskas.github.io/gp3sequences/reference/encode_sequence_data.md)
  creates a transparent state dictionary;
- [`summarise_sequence_states()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_sequence_states.md)
  reports state frequencies and durations;
- [`summarise_sequence_transitions()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_sequence_transitions.md)
  reports adjacent transition counts;
- [`format_sequence_paths()`](https://stefanosbalaskas.github.io/gp3sequences/reference/format_sequence_paths.md)
  creates compact ordered path strings.

``` r

encoded <- encode_sequence_data(
  prepared$data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state"
)

state_summary <- summarise_sequence_states(
  prepared$data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state"
)

transition_summary <- summarise_sequence_transitions(
  prepared$data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state"
)

paths <- format_sequence_paths(
  prepared$data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state"
)
```

## Contiguous motif analysis

The motif workflow enumerates contiguous state windows only and retains
explicit structural definitions:

- [`extract_sequence_ngrams()`](https://stefanosbalaskas.github.io/gp3sequences/reference/extract_sequence_ngrams.md)
  extracts auditable motif occurrences;
- [`summarise_sequence_motifs()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_sequence_motifs.md)
  reports counts and sequence prevalence;
- [`filter_sequence_motifs()`](https://stefanosbalaskas.github.io/gp3sequences/reference/filter_sequence_motifs.md)
  applies explicit transparent thresholds;
- [`format_sequence_motifs()`](https://stefanosbalaskas.github.io/gp3sequences/reference/format_sequence_motifs.md)
  creates stable report-ready tables.

``` r

motif_occurrences <- extract_sequence_ngrams(
  prepared$data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  min_length = 2,
  max_length = 4,
  overlap = "allow"
)

motif_summary <- summarise_sequence_motifs(motif_occurrences)

motif_filter <- filter_sequence_motifs(
  motif_summary,
  min_sequences = 2,
  min_prevalence = 0.10,
  top_n = 20,
  ties = "include"
)

motif_table <- format_sequence_motifs(
  motif_filter,
  prevalence = "percent",
  digits = 1
)
```

### Motif positions and visualisation

Motif occurrences can be summarised and plotted without adding
analytical dependencies:

- [`summarise_sequence_motif_positions()`](https://stefanosbalaskas.github.io/gp3sequences/reference/summarise_sequence_motif_positions.md)
  reports structural locations;
- [`format_sequence_motif_positions()`](https://stefanosbalaskas.github.io/gp3sequences/reference/format_sequence_motif_positions.md)
  produces explicit report tables;
- [`plot_sequence_motifs()`](https://stefanosbalaskas.github.io/gp3sequences/reference/plot_sequence_motifs.md)
  plots prevalence or occurrence metrics;
- [`plot_sequence_motif_positions()`](https://stefanosbalaskas.github.io/gp3sequences/reference/plot_sequence_motif_positions.md)
  plots occurrence locations.

``` r

position_summary <- summarise_sequence_motif_positions(
  motif_occurrences,
  position = "centre",
  scale = "relative"
)

position_table <- format_sequence_motif_positions(
  position_summary,
  position_units = "percent",
  digits = 1
)

plot_sequence_motifs(
  motif_summary,
  metric = "sequence_prevalence",
  top_n = 10
)

plot_sequence_motif_positions(
  motif_occurrences,
  position = "centre",
  scale = "relative",
  top_n = 5
)
```

## Documentation

The package website now provides **15 synthetic, reproducible
articles**:

- getting started with the complete structural workflow;
- sequence-data validation and policy-driven preparation;
- choosing among motifs, consensus, distances, clustering, networks,
  higher-order models, HMMs, and adapters;
- a reproducible integrated synthetic case study;
- contiguous motif analysis and motif positions;
- consensus sequences and descriptive group comparisons;
- sequence distances, clustering, representatives, ensembles, and
  stability;
- transition networks and higher-order models;
- latent sequence models and optional ecosystem adapters;
- longitudinal and panel sequence workflows;
- non-contiguous subsequence mining;
- time-varying condition models;
- multichannel and covariate hidden Markov models;
- design-aware sequence inference and randomization;
- extended sequence visualisations.

The articles use ordinary data frames and synthetic data. They preserve
the package interpretation boundary and do not infer psychological or
causal attributes from structural sequence outputs.

## Current development extensions

The 0.2.0.9000 development series includes the following explicitly
governed workflows:

- longitudinal and panel sequence preparation, summaries, change
  metrics, and plots;
- bounded non-contiguous subsequence mining with explicit gap, span, and
  combination limits;
- optional time-varying state and transition models using `mgcv`;
- multichannel and covariate-dependent categorical hidden Markov models;
- design-aware permutation and bootstrap group comparisons;
- sequence-index, state-distribution, entropy, distance, network, and
  silhouette plots.

These extensions preserve ordinary-data-frame inputs, explicit method
parameters, deterministic seeds, and structural interpretation
boundaries. Inferential helpers record the independent unit and study
design; observational contrasts remain associational, and randomized
contrasts require valid assignment and implementation.

## Interpretation boundary

Sequence outputs describe behavioural or structural patterns only. They
do not independently establish emotion, cognition, comprehension,
personality, intention, diagnosis, deception, or other psychological
attributes. Substantive interpretation requires an appropriate study
design and external evidence.

## Author

**Stefanos Balaskas**

[ORCID](https://orcid.org/0000-0003-2444-9796) · [Personal
website](https://sites.google.com/view/stefbalaskas/) ·
[LinkedIn](https://www.linkedin.com/in/stefanos-balaskas/)

## Licence

`gp3sequences` is released under the MIT License.

## Advanced sequence-analysis methods

The 0.2.0 release established:

- aligned-position consensus sequences and agreement diagnostics;
- descriptive between-group comparisons;
- edit, LCS, optimal-matching, and transition-profile distances;
- clustering, validation, representatives, ensembles, and stability
  analysis;
- transition networks, centrality, communities, and higher-order models;
- categorical HMMs, mixture HMMs, and state decoding;
- optional adapters to specialist sequence-analysis packages.

The current 0.2.0.9000 development series extends that foundation with
longitudinal and panel workflows, bounded non-contiguous subsequences,
time-varying models, multichannel and covariate HMMs, design-aware
inference, extended visualisations, and analysis-contract/provenance
auditing.

These outputs are structural and statistical. They do not independently
establish emotion, cognition, comprehension, personality, intention,
diagnosis, deception, causality, or other psychological attributes.
