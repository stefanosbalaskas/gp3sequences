# gp3sequences

`gp3sequences` is an independent R package for transparent,
reproducible, and auditable analysis of ordered categorical sequences.
It is designed for ordinary long-format data frames and is not
restricted to Gazepoint exports, eye-tracking data, particular hardware,
or proprietary software.

## Development status

The package is in initial development and does not yet provide a stable
public analytical API. The first development series prioritises a
neutral data contract, explicit preprocessing policies, machine-readable
diagnostics, and deterministic structural summaries.

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
