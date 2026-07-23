
# gp3sequences <a href="https://stefanosbalaskas.github.io/gp3sequences/"><img src="man/figures/logo.png" align="right" height="139" alt="gp3sequences website" /></a>

`gp3sequences` is an independent R package for transparent,
reproducible, and auditable analysis of ordered categorical sequences.
It is designed for ordinary long-format data frames and is not
restricted to Gazepoint exports, eye-tracking data, particular hardware,
or proprietary software.

## Development status

Version 0.1.0 established the neutral data contract and contiguous-motif
MVP. The development version adds auditable advanced sequence methods
while retaining explicit interpretation boundaries and optional
specialist-package adapters.

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

The initial public API provides three related functions:

- `audit_sequence_data()` reports structured data-quality issues;
- `validate_sequence_data()` returns a compact validity contract;
- `prepare_sequence_data()` applies explicit preprocessing policies and
  creates deterministic canonical sequence data.

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

## Encoding and structural summaries

Related functions support deterministic encoding and descriptive
sequence summaries without assigning substantive meaning to states:

- `encode_sequence_data()` creates a transparent state dictionary;
- `summarise_sequence_states()` reports state frequencies and durations;
- `summarise_sequence_transitions()` reports adjacent transition counts;
- `format_sequence_paths()` creates compact ordered path strings.

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

- `extract_sequence_ngrams()` extracts auditable motif occurrences;
- `summarise_sequence_motifs()` reports counts and sequence prevalence;
- `filter_sequence_motifs()` applies explicit transparent thresholds;
- `format_sequence_motifs()` creates stable report-ready tables.

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

- `summarise_sequence_motif_positions()` reports structural locations;
- `format_sequence_motif_positions()` produces explicit report tables;
- `plot_sequence_motifs()` plots prevalence or occurrence metrics;
- `plot_sequence_motif_positions()` plots occurrence locations.

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

<!-- advanced-roadmap-start -->

## Advanced sequence-analysis roadmap

The development API extends the audited sequence contract with:

- aligned-position consensus sequences and agreement diagnostics;
- descriptive between-group comparisons;
- edit, LCS, optimal-matching, and transition-profile distances;
- clustering, validation, representatives, ensembles, and stability
  analysis;
- transition networks, centrality, communities, and higher-order models;
- categorical HMMs, mixture HMMs, and state decoding;
- optional adapters to specialist sequence-analysis packages.

These outputs are structural and statistical. They do not independently
establish emotion, cognition, comprehension, personality, intention,
diagnosis, deception, causality, or other psychological attributes.
<!-- advanced-roadmap-end -->
