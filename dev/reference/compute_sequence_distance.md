# Compute pairwise sequence distances

Provides transparent base-R implementations of Levenshtein edit
distance, longest-common-subsequence distance, optimal matching, and a
first-order transition-profile distance.

## Usage

``` r
compute_sequence_distance(
  data,
  sequence_id_col = "sequence_id",
  order_col = "sequence_order",
  state_col = "state",
  method = c("levenshtein", "lcs", "optimal_matching", "transition"),
  indel_cost = 1,
  substitution_cost = 1,
  substitution_matrix = NULL,
  transition_smoothing = 0,
  normalise = c("none", "max_length", "path_length")
)
```

## Arguments

- data:

  Long-format sequence data or a prepared gp3sequences result.

- sequence_id_col, order_col, state_col:

  Sequence columns.

- method:

  Distance method.

- indel_cost:

  Non-negative insertion/deletion cost used by
  `method = "optimal_matching"`.

- substitution_cost:

  Non-negative default substitution cost used by
  `method = "optimal_matching"`.

- substitution_matrix:

  Optional named square substitution-cost matrix for
  `method = "optimal_matching"`.

- transition_smoothing:

  Non-negative smoothing for transition profiles.

- normalise:

  One of `"none"`, `"max_length"`, or `"path_length"`.

## Value

A `dist` object with method and preprocessing metadata attached.

## Examples

``` r
sequences <- data.frame(
  sequence_id = rep(c("s1", "s2", "s3", "s4"), each = 4L),
  sequence_order = rep(1:4, times = 4L),
  state = c("A", "B", "C", "D", "A", "B", "C", "C",
            "D", "C", "B", "A", "D", "C", "A", "A"),
  group = rep(c("g1", "g2"), each = 8L),
  stringsAsFactors = FALSE
)
compute_sequence_distance(sequences, method = "lcs")
#>    s1 s2 s3
#> s2  2      
#> s3  6  6   
#> s4  6  6  2
```
